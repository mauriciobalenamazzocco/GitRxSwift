//
//  ViewModelProtocol.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 03/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.

import Foundation

protocol ViewModelProtocol {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
