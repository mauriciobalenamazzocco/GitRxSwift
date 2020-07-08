//
//  GitServiceMock.swift
//  GitRxSwiftTests
//
//  Created by Mauricio Balena Mazzocco on 05/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//

import Foundation
import RxSwift

@testable import GitRxSwift
class GitServiceMock: GitService {

    var userReturnValue: UserResponse!
    var userUrl: String!
    override func getUser(url: String) -> UserResponse {
        userUrl = url
        return userReturnValue
    }

    var repositoriesUrl: String!
    var repositoriesReturnValue: RespositoriesResponse!

    override func getRepositories(url: String) -> RespositoriesResponse {
        repositoriesUrl = url
        return repositoriesReturnValue
    }

}
