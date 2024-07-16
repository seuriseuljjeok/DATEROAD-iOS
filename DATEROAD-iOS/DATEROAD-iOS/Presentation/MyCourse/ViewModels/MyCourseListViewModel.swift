//
//  MyCourseListViewModel.swift
//  DATEROAD-iOS
//
//  Created by 이수민 on 7/7/24.
//

import Foundation

class MyCourseListViewModel {
    
    var userName = "수민" //나중에 유저디폴트? 아무튼 로직으로 변경
    
    let myCourseService = MyCourseService()
    
    var viewedCourseData : [MyCourseModel] = []
    
    var myRegisterCourseData : [MyCourseModel] = []
    
    var isSuccessGetViewedCourseInfo: ObservablePattern<Bool> = ObservablePattern(false)
    
    var isSuccessGetMyRegisterCourseInfo: ObservablePattern<Bool> = ObservablePattern(false)
    
    init(userName: String = "수민") {
        self.userName = userName
        setViewedCourseData()
        setMyRegisterCourseData()
        print("@log", myRegisterCourseData)
    }
    
    func setViewedCourseData() {
        myCourseService.getViewedCourse() { [weak self] response in
            switch response {
            case .success(let data):
                let viewedCourseInfo = data.courses.map {
                    MyCourseModel(courseId: $0.courseID, thumbnail: $0.thumbnail, title: $0.title, city: $0.city, cost: $0.cost.priceRangeTag(), duration: $0.duration, like: $0.like)
                }
                self?.viewedCourseData = viewedCourseInfo
                self?.isSuccessGetViewedCourseInfo.value = true
            case .requestErr:
                print("requestError")
            case .decodedErr:
                print("decodedError")
            case .pathErr:
                print("pathError")
            case .serverErr:
                print("serverError")
            case .networkFail:
                print("networkFail")
            }
        }
    }
    
    func setMyRegisterCourseData() {
        myCourseService.getMyRegisterCourse() { [weak self] response in
            switch response {
            case .success(let data):
                let myRegisterCourseInfo = data.courses.map {
                    MyCourseModel(courseId: $0.courseID, thumbnail: $0.thumbnail, title: $0.title, city: $0.city, cost: ($0.cost).priceRangeTag(), duration: $0.duration, like: $0.like)
                }
                self?.myRegisterCourseData = myRegisterCourseInfo
                self?.isSuccessGetMyRegisterCourseInfo.value = true
                print("@log-------")
                print(myRegisterCourseInfo)
                print(self?.myRegisterCourseData)
            case .requestErr:
                print("requestError")
            case .decodedErr:
                print("decodedError")
            case .pathErr:
                print("pathError")
            case .serverErr:
                print("serverError")
            case .networkFail:
                print("networkFail")
            }
        }
    }
}
