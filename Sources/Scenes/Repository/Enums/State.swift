//
//  State.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 05/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//

import Foundation

enum State: Equatable {
    case idle
    case loadingPage
    case loadedPage(hasMore: Bool)
    case error(ServiceError)

    static func == (lhs: State, rhs: State) -> Bool {
          switch (lhs, rhs) {
          case (.idle, .idle):
              return true
          case (let .loadedPage(hasMore1), let .loadedPage(haMore2)):
              return hasMore1 == haMore2
          case (let .error(error1), let .error(error2)):
              return error1.localizedDescription == error2.localizedDescription
          case (.loadingPage, .loadingPage):
              return true
          default:
              return false
          }
      }
}
