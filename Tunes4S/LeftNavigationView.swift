//
//  NavigationView.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 01/08/22.
//

import SwiftUI


struct LeftNavigationView: View {

    
    let options: [Option] = [
        .init(title: "Home", imageName: "house"),
        .init(title: "Search", imageName: "magnifyingglass"),
        .init(title: "Library", imageName: "books.vertical"),
        .init(title: "My Playlists", imageName: "message"),
        .init(title: "Settings", imageName: "gear"),
    ];
    
    var body: some View {
        VStack {
            ForEach(options, id: \.self) { option in
                HStack {
                    Image(systemName: option.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                    Text(option.title)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment:.leading)
            }
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}

//    struct ListView: View {
//        let options: [Option]
//        var body: some View {
//            VStack {
//                ForEach(options, id: \.self) { option in
//                    HStack {
//                        Image(systemName: option.imageName)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 30)
//                        Text(option.title)
//                        Spacer()
//                    }
//                }
//                .padding()
//            }
//        }
//    }

struct LeftNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        LeftNavigationView()
    }
}
