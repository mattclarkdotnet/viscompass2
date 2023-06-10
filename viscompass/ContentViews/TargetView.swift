//
//  TargetView.swift
//  viscompass2
//
//  Created by Matt Clark on 10/6/2023.
//

import Foundation
import SwiftUI

struct TargetView: View {
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
            Text("Target").font(.title)
            ZStack {
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
                            .background(Circle()
                                .fill(.radialGradient(colors: [self.longpress_colour(), Color(UIColor.systemBackground)], center: .center, startRadius: 30, endRadius: 100))
                                .foregroundColor(self.longpress_colour())
                                .frame(width: self.longpress() ? 200 : 0, height: self.longpress() ? 200 : 0)
                                )
                        
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
    }
}
