import SwiftUI

struct EmptyStateView: View {
    let hasContacts: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if hasContacts {
                // Has contacts but filtered to empty
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("No matching contacts")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            } else {
                // No contacts at all
                VStack(spacing: 16) {
                    Text("✨")
                        .font(.system(size: 50))
                    
                    Text("Welcome to Astro Friends!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Add your friends and discover their\nzodiac signs and compatibility.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Text("Tap + to get started")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}
