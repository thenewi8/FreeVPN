//
//  PlanProducts.swift
//  freevpn_mac
//
//  Created by zhou ligang on 06/10/2016.
//  Copyright © 2016 zhou ligang. All rights reserved.
//

import Foundation

public struct PlanProducts {
    
    fileprivate static let Prefix = "com.ligulfzhou.freevpn_mac."
    
    public static let OneMonthPlan = Prefix + "one_month_vpn_plan"
    public static let QuarterPlan = Prefix + "quarter_vpn_plan"
    public static let HalfYearPlan = Prefix + "half_year_vpn_plan"
    public static let OneYearPlan = Prefix + "one_year_vpn_plan"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [PlanProducts.OneMonthPlan, PlanProducts.QuarterPlan, PlanProducts.HalfYearPlan, PlanProducts.OneYearPlan]
    
    public static let store = IAPHelper(productIds: PlanProducts.productIdentifiers)
}
