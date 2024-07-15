//
//  ViewedCourseAPITarget.swift
//  DATEROAD-iOS
//
//  Created by 이수민 on 7/16/24.
//

import Foundation

import Moya

enum MyCourseAPI {
    case viewedCourse
    case myRegisterCourse
}

extension MyCourseAPI: BaseTargetType {
    var utilPath: String {
        return "/api/v1/courses"
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var path: String {
        switch self {
        case .viewedCourse:
            return self.utilPath + "/date-access"
        case .myRegisterCourse:
            return self.utilPath + "/users"
        }
    }
    
    var task: Moya.Task {
        return .requestPlain
    }


}
