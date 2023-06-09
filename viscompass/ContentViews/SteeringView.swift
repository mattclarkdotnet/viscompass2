//
//  SteeringView.swift
//  viscompass
//
//  Created by Matt Clark on 10/5/2023.
//

import Foundation
import SwiftUI

struct SteeringView: View {
    @EnvironmentObject var steeringModel: SteeringModel
    
    @GestureState private var isDetectingLongPressPlus = false
    @State private var completedLongPressPlus = false
    @GestureState private var isDetectingLongPressMinus = false
    @State private var completedLongPressMinus = false
    @GestureState private var isDetectingLongPressTarget = false
    @State private var completedLongPressTarget = false
    
    func longpress_colour() -> Color {
        if self.isDetectingLongPressTarget {
            return Color.blue
        }
        if self.isDetectingLongPressMinus {
            return Color.red
        }
        if self.isDetectingLongPressPlus {
            return Color.green
        }
        return Color(UIColor.systemBackground)
    }
    
    func longpress() -> Bool {
        return self.isDetectingLongPressPlus || self.isDetectingLongPressMinus || self.isDetectingLongPressTarget
    }

    var longPressTargetPlus: some Gesture {
        LongPressGesture(minimumDuration: 2)
            .updating($isDetectingLongPressPlus) { currentState, gestureState,
                    transaction in
                gestureState = currentState
                transaction.animation = Animation.easeIn(duration: 2.0)
            }
            .onEnded { finished in
                self.completedLongPressPlus = finished
                logger.debug("Long press on starboard detected")
                steeringModel.tack(turn: .stbd)
            }
    }
    
    var longPressTargetMinus: some Gesture {
        LongPressGesture(minimumDuration: 2)
            .updating($isDetectingLongPressMinus) { currentState, gestureState,
                    transaction in
                gestureState = currentState
                transaction.animation = Animation.easeIn(duration: 2.0)
            }
            .onEnded { finished in
                self.completedLongPressMinus = finished
                logger.debug("Long press on port detected")
                steeringModel.tack(turn: .port)
            }
    }
    
    var longPressTarget: some Gesture {
        LongPressGesture(minimumDuration: 2)
            .updating($isDetectingLongPressTarget) { currentState, gestureState,
                    transaction in
                gestureState = currentState
                transaction.animation = Animation.easeIn(duration: 2.0)
            }
            .onEnded { finished in
                self.completedLongPressTarget = finished
                logger.debug("Long press on target detected")
                steeringModel.setTarget(target: steeringModel.headingSmoothed)
            }
    }

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width:50, height:50)
                    Spacer()
                    Text(Int(steeringModel.headingSmoothed).description + "º").font(.system(size: 50))
                    Spacer()
                    Button(action: {
                        steeringModel.toggleAudioFeedback()
                    }) {
                        Image(systemName: steeringModel.audioFeedbackOn ? "pause.circle" : "play.circle")
                            .resizable()
                            .frame(width:50, height:50)
                    }
                }
            }
            Divider()
            VStack {
                Text("Target").font(.title)
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .padding(.all, 0)
                        .background(Circle()
                            .fill(.radialGradient(colors: [self.longpress_colour(), Color(UIColor.systemBackground)], center: .center, startRadius: 30, endRadius: 100))
                            .foregroundColor(self.longpress_colour())
                            .frame(width: self.longpress() ? 200 : 0, height: self.longpress() ? 200 : 0)
                            )
                        .ignoresSafeArea()
                        
                    HStack {
                        Button(action: steeringModel.decreaseTarget) {
                            Image(systemName: "minus.square")
                                .resizable()
                                .frame(width:50, height:50)
                                .gesture(longPressTargetMinus)
                        }
                        Spacer()
                        VStack {
                            Text(Int(steeringModel.headingTarget).description + "º")
                                .font(.system(size: 50))
                                .gesture(longPressTarget)
                            
                        }
                        Spacer()
                        Button(action: steeringModel.increaseTarget) {
                            Image(systemName: "plus.square")
                                .resizable()
                                .frame(width:50, height:50)
                                .gesture(longPressTargetPlus)
                        }
                    }
                }
            }
            Divider()
            VStack {
                Text("Steer").font(.title)
                HStack {
                    Image(systemName: "arrowtriangle.left.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(steeringModel.correctingNow() == .port ? .red : .gray)
                    
                    VStack {
                        Text(Int(steeringModel.correctionAmount).description + "º")
                            .font(.system(size: 50))
                    }.frame(minWidth: 130)
                    Image(systemName: "arrowtriangle.right.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(steeringModel.correctingNow() == .stbd ? .green : .gray)
                    
                }
            }
            Divider()
            Spacer()
            VStack {
                Spacer()
                FeedbackPickerView()
                TolerancePickerView()
                ResponsivenessPickerView()
            }
        }
        .padding()
        .onAppear(perform: { steeringModel.audioFeedbackModel.setFeedbackMode(mode: .steering) })
    }
}


struct Previews_SteeringView_Previews: PreviewProvider {
    static var previews: some View {
        SteeringView()
            .environmentObject(SteeringModel())
    }
}
