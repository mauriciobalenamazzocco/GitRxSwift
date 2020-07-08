//
//  GitService.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 04/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum ServiceError: Error {
    case parseError
    case urlInvalid
}

class GitService {
    private let session: URLSession
    typealias RespositoriesResponse = Observable<Result<ListPage<Repository>, ServiceError>>
    typealias UserResponse = Observable<Result<User, ServiceError>>

    init(session: URLSession = URLSession.shared) {
        self.session = session
    }

    func getRepositories(url: String) -> RespositoriesResponse {

        guard let url = URL(string: url) else {
            return .just(.failure(.urlInvalid))
        }
        return session.rx
            .response(request: URLRequest(url: url))
            .flatMap({ (response, data) throws -> RespositoriesResponse in
                guard let colectionResponse = try? JSONDecoder().decode(ApiCollectionResponseCodable<Repository>.self, from: data) else {
                    return .just(.failure(.parseError))
                }

                let nextUrl = response.allHeaderFields["Link"] as? String
                let list = nextUrl?.extractUrl()
                let listPage = ListPage(items: colectionResponse.items, page: list ?? "", hasNext: list != nil)
                return .just(.success(listPage))

            })
    }

    func getUser(url: String) -> UserResponse {
        guard let url = URL(string: url) else {
            return .just(.failure(.urlInvalid))
        }
        return session
            .rx
            .data(request: URLRequest(url: url))
            .flatMap { data throws -> UserResponse in
                guard let user = try? JSONDecoder().decode(User.self, from: data) else {
                   return .just(.failure(.parseError))
                }
                return .just(.success(user))
            }
    }
}

extension GitService {
    static let apiRepositoryPath = "https://api.github.com/search/repositories?q=language%3Aswift&sort=stars"
}
