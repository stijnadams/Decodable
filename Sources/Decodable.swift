//
//  Decodable.swift
//  Decodable
//
//  Created by Johannes Lund on 2015-07-07.
//  Copyright © 2015 anviking. All rights reserved.
//

import Foundation

public protocol Decodable {
    static func decode(_ json: JSON) throws -> Self
}


extension Dictionary: Decodable where Key: Decodable, Value: Decodable {
    public static func decode(_ j: JSON) throws -> Dictionary {
        return try Dictionary.decoder(key: Key.decode, value: Value.decode)(j)
    }
}

extension Array: Decodable where Element: Decodable {
    public static func decode(_ j: JSON) throws -> Array {
        return try Array.decoder(Element.decode)(j)
    }
}

extension Optional: Decodable where Wrapped: Decodable {
    public static func decode(_ j: JSON) throws -> Optional {
        return try Optional.decoder(Wrapped.decode)(j)
    }
}

/* FIXME: this causes ambiguity issues, in the meantime resort to `Dictionary.decoder`
 https://github.com/Anviking/Decodable/issues/120
 
extension Dictionary where Key: Decodable, Value: Any {
    
    public static func decode(_ j: JSON) throws -> Dictionary {
        let valueDecoder: (Any) throws -> Value = { try cast($0) }
        return try Dictionary.decoder(key: Key.decode, value: valueDecoder)(j)
    }
}
*/

extension Array where Element: Decodable {
    public static func decode(_ j: JSON, ignoreInvalidObjects: Bool = false) throws -> [Element] {
        if ignoreInvalidObjects {
            return try [Element?].decoder { try? Element.decode($0) }(j).flatMap {$0}
        } else {
            return try Array.decoder(Element.decode)(j)
        }
    }
}




// MARK: Helpers

/// Attempt to decode one of multiple objects in order until: A: we get a positive match, B: we throw an exception if the last object does not decode
public func decodeAsOneOf(_ json: JSON, objectTypes: Decodable.Type...) throws -> Decodable {
	for decodable in objectTypes.dropLast() {
		if let decoded = try? decodable.decode(json) {
			return decoded
		}
	}
	return try objectTypes.last!.decode(json)
}

/// Attempt to decode one of multiple objects in order until: A: we get a positive match, B: we throw an exception if the last object does not decode
public func decodeArrayAsOneOf(_ json: JSON, objectTypes: Decodable.Type...) throws -> [Decodable] {
	return try NSArray.decode(json).map {
		for decodable in objectTypes.dropLast() {
            if let decoded = try? decodable.decode(JSON(object: $0)) {
				return decoded
			}
		}
		return try objectTypes.last!.decode(JSON(object: $0))
	}
}
