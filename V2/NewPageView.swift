import SwiftUI

struct NewPageView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Visuo-Spatial Task")
                    .font(.title)
                    .padding()
                
                Text("Please click in the order 1 -> A -> 2 -> B -> .....")
                    .font(.body)
                    .padding()
                
                Spacer()
                
                RandomCirclesView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                NavigationLink(destination: ClockTestView()) {
                    Text("Proceed")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("New Task")
        }
    }
}

struct RandomCirclesView: View {
    let items = ["1", "A", "2", "B", "3", "C", "4", "D", "5", "E"]
    let correctOrder = ["1", "A", "2", "B", "3", "C", "4", "D", "5", "E"] // The correct order as an array
    @State private var clickedItems: [String] = [] // Array to store clicked order
    @State private var clickedStates: [String: Bool] = [:] // Dictionary to track clicked states
    @State private var showingAlert = false // To show alert
    @State private var alertMessage = "" // Message to display in the alert
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<items.count, id: \.self) { index in
                    CircleButtonView(item: items[index], isClicked: clickedStates[items[index]] ?? false) {
                        buttonClicked(items[index])
                    }
                    .position(positionForItem(at: index, in: geometry.size))
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Result"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // Update the clicked state and order
    func buttonClicked(_ item: String) {
        if clickedStates[item] != true { // Check if the item hasn't been clicked yet
            clickedItems.append(item)
            clickedStates[item] = true
            
            // Check if all items have been clicked
            if clickedItems.count == items.count {
                if clickedItems == correctOrder {
                    alertMessage = "Correct order!"
                } else {
                    alertMessage = "Incorrect order. Try again!"
                }
                showingAlert = true
            }
        }
    }
    
    // Dynamic positioning based on screen size
    func positionForItem(at index: Int, in size: CGSize) -> CGPoint {
        let relativePositions: [CGPoint] = [
            CGPoint(x: 0.2, y: 0.1), // 1
            CGPoint(x: 0.8, y: 0.1), // A
            CGPoint(x: 0.5, y: 0.2), // 2
            CGPoint(x: 0.4, y: 0.4), // B
            CGPoint(x: 0.7, y: 0.5), // 3
            CGPoint(x: 0.2, y: 0.6), // C
            CGPoint(x: 0.8, y: 0.7), // 4
            CGPoint(x: 0.3, y: 0.75), // D
            CGPoint(x: 0.7, y: 0.9), // 5
            CGPoint(x: 0.2, y: 0.9)  // E
        ]
        
        let posX = relativePositions[index].x * size.width
        let posY = relativePositions[index].y * size.height
        return CGPoint(x: posX, y: posY)
    }
}

struct CircleButtonView: View {
    let item: String
    let isClicked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(item)
                .font(.largeTitle)
                .frame(width: 70, height: 70)
                .background(Circle().fill(isClicked ? Color.green : Color.blue))
                .foregroundColor(.white)
                .overlay(Circle().stroke(Color.black, lineWidth: 2)) // Add border to match the style
        }
    }
}

struct NewPageView_Previews: PreviewProvider {
    static var previews: some View {
        NewPageView()
    }
}
