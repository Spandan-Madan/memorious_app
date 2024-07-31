import SwiftUI

struct ContentView: View {
    @State private var navigateToQuestionnaire = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                        )
                    
                    Text("Welcome")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("We hope to assist your memory loss with AI.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        // Action for Sign up
                    }) {
                        Text("Sign up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        navigateToQuestionnaire = true
                    }) {
                        Text("Log in")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(
                NavigationLink(destination: QuestionnaireView(), isActive: $navigateToQuestionnaire) {
                    EmptyView()
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
