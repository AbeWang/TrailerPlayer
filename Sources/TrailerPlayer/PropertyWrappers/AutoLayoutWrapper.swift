//
//  AutoLayoutWrapper.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/1.
//

import UIKit

@propertyWrapper
public struct AutoLayout<T: UIView> {
    public var wrappedValue: T {
        didSet {
            wrappedValue.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
        self.wrappedValue.translatesAutoresizingMaskIntoConstraints = false
    }
}
