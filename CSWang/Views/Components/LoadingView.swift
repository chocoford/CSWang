//
//  LoadingView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct LoadingView<Content: View>: View {
    @State private var loading: Bool = false
    @State private var degree: CGFloat = 0
    
    @State private var trimLength: CGFloat = 0
    
    var progress: Float
    var indeterminate: Bool
    
    @State private var indeterminateLoading = true
    @State private var isProgessReady = false
    
    @State private var progressValue: Int = 0
    @State private var progressTimer: Timer? = nil
    
//    @State private var loadingBegin: CGFloat = 0
//    @State private var loadingEnd: CGFloat = 0
    
    var size: CGFloat
    var lineWidth: CGFloat
    var content: ((_ progress: Int) -> Content)?
    
    init(size: CGFloat = 50, lineWidth: CGFloat = 4) where Content == EmptyView {
        self.content = nil
        self.size = size
        self.progress = 0
        self.indeterminate = true
        self.lineWidth = lineWidth
    }
    
    init(size: CGFloat = 50, lineWidth: CGFloat = 4,
         @ViewBuilder content: @escaping (_ progress: Int) -> Content) {
        self.content = content
        self.size = size
        self.progress = 0
        self.indeterminate = true
        self.lineWidth = lineWidth
    }
    
    init(size: CGFloat = 50, lineWidth: CGFloat  = 4, progress: Float,
         @ViewBuilder content: @escaping (_ progress: Int) -> Content) {
        self.content = content
        self.size = size
        self.progress = progress
        self.indeterminate = false
        self.lineWidth = lineWidth
    }

    
//    init(size: CGFloat = 50, lineWidth: CGFloat  = 4, progress: Float) {
//        self.content = nil
//        self.size = size
//        self.progress = progress
//        self.indeterminate = false
//        self.lineWidth = lineWidth
//    }
    
    var animationDuration: Double = 0.8
    
    var rotatingAnimation: Animation {
        Animation.linear(duration: animationDuration)
            .repeatForever(autoreverses: false)
    }
    
    var trimAnimation: Animation {
        Animation.easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if indeterminateLoading {
                    Circle()
                        .trim(from: 0.2 + trimLength, to: 1 - trimLength)
                        .stroke(
                            LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)), Color(#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1))]),
                                           startPoint: .topTrailing,
                                           endPoint: .bottomLeading),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(Angle(degrees: degree))
                        .onAppear {
                            withAnimation(rotatingAnimation) {
                                degree = 360
                            }
                            withAnimation(trimAnimation) {
                                trimLength = 0.38
                            }
                        }
                } else {
                    ZStack {
                        Circle()
                            .stroke(
                                Color.gray.opacity(0.5),
                                lineWidth: lineWidth
                            )
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)), Color(#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1))]),
                                               startPoint: .topTrailing, endPoint: .bottomLeading),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: -90))
                        
                    }
                    .animation(.linear(duration: 0.5), value: progress)
                    .frame(width: size, height: size)
                    .onAppear {
                        isProgessReady = true
                    }
                }
                if let content = content {
                    content(progressValue)
                }
                
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .onChange(of: progress) { p in
                if p > 0 {
                    indeterminateLoading = false
                } else if indeterminateLoading {
                    var localProgrss: Float = Float(self.progressValue)
                    self.progressTimer?.invalidate()
                    let difference = 100 * p - localProgrss
                    /// 默认500ms
                    self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                        localProgrss += difference / 50
                        self.progressValue = Int(localProgrss)
                        if localProgrss >= 100 * p {
                            timer.invalidate()
                        }
                    }
                }
            }
        }
        
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
