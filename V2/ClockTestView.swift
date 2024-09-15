import SwiftUI
import UIKit

extension UIApplication {
    func endEditing(_ force: Bool = false) {
        self.windows
            .filter { $0.isKeyWindow }
            .first?
            .endEditing(force)
    }
    
    func presentAlert(title: String, message: String, on viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}

struct ClockTestView: View {
    @State private var positions: [String] = Array(repeating: "", count: 12)
    @State private var currentTime = Date()
    @State private var gtPositions = ["12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"]
    @State private var score = 0
    
    let circleSize: CGFloat = 300
    let textBoxSize: CGFloat = 40
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @FocusState private var focusedField: Int?

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    // Background Circle (Clock Face)
                    Circle()
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                    
                    // Clock numbers
                    ForEach(1...12, id: \.self) { hour in
                        Text("\(hour)")
                            .font(.system(size: 14, weight: .bold))
                            .position(positionForHour(hour, in: CGSize(width: circleSize, height: circleSize)))
                    }
                    
                    // Clock hands
                    ClockHands(currentTime: currentTime)
                        .frame(width: circleSize, height: circleSize)
                    
                    // Text Boxes
                    ForEach(0..<12, id: \.self) { index in
                        TextField("", text: $positions[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: textBoxSize, height: textBoxSize)
                            .background(Color(UIColor.systemBackground))
                            .overlay(Circle().stroke(Color.primary, lineWidth: 3))
                            .position(positionForItem(at: index, in: CGSize(width: circleSize, height: circleSize)))
                            .focused($focusedField, equals: index)
                            .onSubmit {
                                if index < 11 {
                                    focusedField = index + 1
                                } else {
                                    focusedField = nil
                                    UIApplication.shared.endEditing() // Dismiss keyboard
                                }
                            }
                    }
                }
                .frame(width: circleSize, height: circleSize)
                .padding()
                
                Text("Complete the clock by adding numbers.")
                    .font(.headline)
                    .padding(.top)
                
                Spacer()
                Spacer()
                Spacer()
                
                Button(action: submit) {
                    Text("Submit")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                
//                Spacer()
            }
            .frame(width: geometry.size.width)
            .padding()
            .onAppear {
                focusedField = 0 // Start focus on the first position
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarHidden(true)
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    func positionForItem(at index: Int, in size: CGSize) -> CGPoint {
        let angle = (CGFloat(index) * .pi / 6) - .pi / 2
        let radius = min(size.width, size.height) / 2 - textBoxSize / 2 - 20
        let x = size.width / 2 + radius * cos(angle)
        let y = size.height / 2 + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    func positionForHour(_ hour: Int, in size: CGSize) -> CGPoint {
        let angle = (CGFloat(hour) * .pi / 6) - .pi / 2
        let radius = min(size.width, size.height) / 2 - 30
        let x = size.width / 2 + radius * cos(angle)
        let y = size.height / 2 + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    func submit() {
        printText()
        
        // Present the alert
        if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            UIApplication.shared.presentAlert(title: "Score", message: "Your score is \(score)", on: viewController)
        }
    }
    
    func printText() {
        print(positions)
        score = 0 // Reset score before calculation
        for i in 0..<positions.count {
            if positions[i] == gtPositions[i] {
                score += 1
            }
        }
        print(score) // For debugging
    }
}

struct ClockHands: View {
    let currentTime: Date
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Hour hand
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 4, height: geometry.size.width * 0.2)
                    .offset(y: -geometry.size.width * 0.1)
                    .rotationEffect(Angle.degrees(Double(Calendar.current.component(.hour, from: currentTime) % 12) * 30))
                
                // Minute hand
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 3, height: geometry.size.width * 0.3)
                    .offset(y: -geometry.size.width * 0.15)
                    .rotationEffect(Angle.degrees(Double(Calendar.current.component(.minute, from: currentTime)) * 6))
                
                // Second hand
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 1, height: geometry.size.width * 0.35)
                    .offset(y: -geometry.size.width * 0.175)
                    .rotationEffect(Angle.degrees(Double(Calendar.current.component(.second, from: currentTime)) * 6))
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct ClockTestView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ClockTestView()
                .preferredColorScheme(.light)
            ClockTestView()
                .preferredColorScheme(.dark)
        }
    }
}
