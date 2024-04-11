//
//  File.swift
//  
//
//  Created by Alessio Moiso on 11/04/24.
//

import Foundation

public enum ProvidersError: Error {
	case 	userCancelled,
				unexpected(Error?),
				unknown
}
