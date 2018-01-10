//
//  HKMapViewController.m
//  HKBaiduMapDemo
//
//  Created by houke on 2018/1/8.
//  Copyright © 2018年 houke. All rights reserved.
//

#import "HKMapViewController.h"
#import "MBProgressHUD.h"

#define screen_Width [UIScreen mainScreen].bounds.size.width
#define screen_Height [UIScreen mainScreen].bounds.size.height

/**
 实现需求:1、显示地图
    2、地图定位
    3、利用反向地理编码实现定位点的位置名称查询
    4、利用（正向）地理编码实现路线规划
 
 地理编码：通过城市名成，位置信息等查到该地点的经纬度
 反向地理编码：通过经纬度查到位置名称
 */
@interface HKMapViewController ()<BMKGeneralDelegate,BMKMapViewDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,BMKRouteSearchDelegate>

//地图对象
@property (nonatomic, strong) BMKMapView *mapView;

//声明定位服务对象属性（负责定位）
@property (nonatomic, strong) BMKLocationService *locationService;
@property (nonatomic, strong) BMKUserLocation *userLocation;

//声明地址位置搜索对象(负责地理编码)
@property (nonatomic, strong) BMKGeoCodeSearch * geoCodeSearch;

//声明路线搜索服务对象
@property (nonatomic, strong) BMKRouteSearch *routeSearch;

//开始的路线检索节点
@property (nonatomic, strong) BMKPlanNode *startNode;

//目标的路线检索节点
@property (nonatomic, strong) BMKPlanNode *endNode;



@property (weak, nonatomic) IBOutlet UITextField *startCityTF;
@property (weak, nonatomic) IBOutlet UITextField *startAddressTF;

@property (weak, nonatomic) IBOutlet UITextField *endCityTF;
@property (weak, nonatomic) IBOutlet UITextField *endAddressTF;


@end

@implementation HKMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //创建百度地图主引擎类对象(使用百度地图功能之前必需启动引擎)
    //核心引擎 用 c++写的
    BMKMapManager *manager = [[BMKMapManager alloc] init];
    //启动引擎
    [manager start:@"7FHwGqD3HKOv4Y5FdSYwvM7yQKzgUGRS" generalDelegate:self];
    
    //创建地图对象(实现地图基本查看功能)
    CGFloat originY = [UIApplication sharedApplication].statusBarFrame.size.height+self.navigationController.navigationBar.frame.size.height;
    self.mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, originY, screen_Width , screen_Height - originY)];
    self.mapView.delegate = self;
    [self.view insertSubview:self.mapView belowSubview:_startCityTF];
    
    
    //创建定位服务对象
    self.locationService = [[BMKLocationService alloc] init];
    self.locationService.delegate = self;
    //设置再次定位的最小距离
    self.locationService.distanceFilter = 10;//超过该距离后会再次定位
    
    
    //创建地理位置搜索对象
    self.geoCodeSearch = [[BMKGeoCodeSearch alloc] init];
    self.geoCodeSearch.delegate = self;
    
    
    //创建路线搜索服务对象
    self.routeSearch = [[BMKRouteSearch alloc] init];
    self.routeSearch.delegate = self;
}


//开始定位
- (IBAction)leftAction:(UIBarButtonItem *)sender {
    //开启定位服务
    [self.locationService startUserLocationService];
    //在地图上显示用户的位置
    self.mapView.showsUserLocation = YES;
    
}

//关闭定位
- (IBAction)rightAction:(UIBarButtonItem *)sender {
    NSLog(@"关闭定位");
    //关闭定位服务
    [self.locationService stopUserLocationService];
    //设置地图不显示用户的位置
    self.mapView.showsUserLocation = NO;
     //删除插入地图中的标注对象
    [self.mapView removeAnnotations:self.mapView.annotations];
    
}

-(void)getStartEndNote
{
    [self.startCityTF resignFirstResponder];
    [self.endAddressTF resignFirstResponder];
    
    self.startNode = [[BMKPlanNode alloc]init];
    _startNode.name = _startAddressTF.text;
    _startNode.cityName = _startCityTF.text;
    self.endNode = [[BMKPlanNode alloc]init];
    _endNode.name = _endAddressTF.text;
    _endNode.cityName = _endCityTF.text;
}
//驾车路线规划
- (IBAction)routeSearch:(id)sender {
    [self getStartEndNote];
    //开始进行路线规划
    if (self.startNode != nil && self.endNode !=nil) {
        //创建驾车路线规划
        BMKDrivingRoutePlanOption *drivingRoutePlanOption = [[BMKDrivingRoutePlanOption alloc] init];
        drivingRoutePlanOption.from = _startNode;
        drivingRoutePlanOption.to = _endNode;
        drivingRoutePlanOption.drivingRequestTrafficType = BMK_DRIVING_REQUEST_TRAFFICE_TYPE_NONE;//不获取路况信息
        [self.routeSearch drivingSearch:drivingRoutePlanOption];
    }
    
}
- (IBAction)subwayRoutePlan:(UIButton *)sender {
    [self getStartEndNote];
    //公交路线规划
    if (self.startNode != nil && self.endNode !=nil) {
        BMKTransitRoutePlanOption *transitRoutePlanOption = [[BMKTransitRoutePlanOption alloc] init];
        transitRoutePlanOption.city = _startCityTF.text;
        transitRoutePlanOption.from = _startNode;
        transitRoutePlanOption.to = _endNode;
        
        if ([self.routeSearch transitSearch:transitRoutePlanOption]) {
            NSLog(@"公交路线检索成功");
        }else{
            NSLog(@"公交路线检索失败");
        }
    }
}

- (IBAction)walkRoutePlan:(UIButton *)sender {
    
    [self getStartEndNote];
    //步行路线规划
    if (self.startNode != nil && self.endNode !=nil) {
        BMKWalkingRoutePlanOption *walkRoutePlanOption = [[BMKWalkingRoutePlanOption alloc] init];
        walkRoutePlanOption.from = _startNode;
        walkRoutePlanOption.to = _endNode;
        
        if ([self.routeSearch walkingSearch:walkRoutePlanOption]) {
            NSLog(@"步行路线检索成功");
        }else{
            NSLog(@"步行路线检索失败");
        }
    }
}
- (IBAction)rideRoutePlan:(UIButton *)sender {
    [self getStartEndNote];
    //骑行路线规划
    if (self.startNode != nil && self.endNode !=nil) {
        BMKRidingRoutePlanOption *rideRoutePlanOption = [[BMKRidingRoutePlanOption alloc] init];
        rideRoutePlanOption.from = _startNode;
        rideRoutePlanOption.to = _endNode;
        
        if ([self.routeSearch ridingSearch:rideRoutePlanOption]) {
            NSLog(@"骑行路线检索成功");
        }else{
            NSLog(@"骑行路线检索失败");
        }
    }
}

#pragma mark BMKlocationServieceDelegate 定位服务代理方法
-(void)willStartLocatingUser
{
    NSLog(@"开始定位");
}

-(void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"定位失败---%@",error.description);
}

/**
 定位成功，再次定位的方法
 */
-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    _userLocation = userLocation;
    [self.mapView updateLocationData:userLocation];
    
    /**
     定位成功回调方法，定位成功后，完成当前位置的反向地理编码，然后在定位到的位置上插入一个大头针
     点击大头针时，出现提示框,显示当前定位位置的详细信息(涉及到反地理编码)
     */
    
    //完成地理反编码
    //1、创建反向地理编码选项对象
    BMKReverseGeoCodeOption *reverseOption = [[BMKReverseGeoCodeOption alloc] init];
    //2、给反向地理编码选项对象的坐标点赋值
    reverseOption.reverseGeoPoint = userLocation.location.coordinate;
//    NSLog()
    //3、执行反向地理编码操作
    [self.geoCodeSearch reverseGeoCode:reverseOption];

}

#pragma mark GeoCodeSearchDelegate地理编码搜索对象的代理回调
//反向地理编码回调方法
-(void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    /*
     成功获取反向地理编码后，modify userLocation
     */
    
    _userLocation.title = result.address;
    _userLocation.subtitle = @"副标题";
    [self.mapView updateLocationData:_userLocation];

}


#pragma mark RouteSearchDelegate 路线搜索代理方法
-(void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    //  删除原来的覆盖物
    NSArray *array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    
    //  删除overlays(原来的轨迹)
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    
    if (error == BMK_SEARCH_NO_ERROR) {
        //选取获取到第一条路线
        BMKDrivingRouteLine *planLine = result.routes[0];
        //计算路线中的路段数目（路线是由路段组成、路段由轨迹点组成）
        NSInteger size = planLine.steps.count;
        //计算轨迹点
        int  planPointsCount = 0;
        for (int i = 0; i<size; i++) {
            //获取路线中的路段
            BMKDrivingStep *step = planLine.steps[i];
            if (i ==0) {
                //地图显示经纬区域
                [self.mapView setRegion:BMKCoordinateRegionMake(step.entrace.location, BMKCoordinateSpanMake(0.01, 0.01))];
            }
            //累计轨迹点
            planPointsCount += step.pointsCount;
            
        }
        //结构体数组用来保存所有的轨迹点(每一个轨迹点是一个包含 x、y 的结构体)
        //轨迹点结构体数组
        BMKMapPoint *tempPoints = new BMKMapPoint[planPointsCount];
        int i =0;
        for (int j = 0; j <planLine.steps.count; j++) {
            BMKDrivingStep *step = planLine.steps[j];
            
            for (int k = 0; k<step.pointsCount; k++) {
                //获取路段中的轨迹点的 x、y 放入数组中
                tempPoints[i].x = step.points[k].x;
                tempPoints[i].y = step.points[k].y;
                i++;
            }
        }
        
        //通过轨迹点构造 BMKPolyline(折线)
        BMKPolyline *polyLine = [BMKPolyline polylineWithPoints:tempPoints count:planPointsCount];
        //把 polyline折线添加到 mapview（mapview 有多种 overlay覆盖图，polyline折线是其中一种)
        [self.mapView addOverlay:polyLine];
        delete []tempPoints;
    }else{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = [NSString stringWithFormat:@"error:%d,地址模糊，重新输入",error];
        [self.view addSubview:hud];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:3.f];
    }
}
- (void)onGetTransitRouteResult:(BMKRouteSearch*)searcher result:(BMKTransitRouteResult*)result errorCode:(BMKSearchErrorCode)error
{
    NSLog(@"onGetTransitRouteResult error:%d", (int)error);
    NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKTransitRouteLine* plan = (BMKTransitRouteLine*)[result.routes objectAtIndex:0];
        // 计算路线方案中的路段数目
        NSInteger size = [plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKTransitStep* transitStep = [plan.steps objectAtIndex:i];
            
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }
        
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKTransitStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        [_mapView addOverlay:polyLine]; // 添加路线overlay
        delete []temppoints;
    }else{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = [NSString stringWithFormat:@"error:%d,地址模糊，重新输入",error];
        [self.view addSubview:hud];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:3.f];
    }
}

-(void)onGetWalkingRouteResult:(BMKRouteSearch *)searcher result:(BMKWalkingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    NSLog(@"onGetWalkingRouteResult error:%d", (int)error);
    NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKWalkingRouteLine* plan = (BMKWalkingRouteLine*)[result.routes objectAtIndex:0];
        NSInteger size = [plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKWalkingStep* transitStep = [plan.steps objectAtIndex:i];
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }
        
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKWalkingStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        [_mapView addOverlay:polyLine]; // 添加路线overlay
        delete []temppoints;
    }else{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = [NSString stringWithFormat:@"error:%d,地址模糊，重新输入",error];
        [self.view addSubview:hud];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:3.f];
    }
}

- (void)onGetRidingRouteResult:(BMKRouteSearch *)searcher result:(BMKRidingRouteResult *)result errorCode:(BMKSearchErrorCode)error {
    NSLog(@"onGetRidingRouteResult error:%d", (int)error);
    NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKRidingRouteLine* plan = (BMKRidingRouteLine*)[result.routes objectAtIndex:0];
        NSInteger size = [plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKRidingStep* transitStep = [plan.steps objectAtIndex:i];
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }
        
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKRidingStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        [_mapView addOverlay:polyLine]; // 添加路线overlay
        delete []temppoints;
        
    }else{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = [NSString stringWithFormat:@"error:%d,地址模糊，重新输入",error];
        [self.view addSubview:hud];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:3.f];
    }
}
#pragma mark mapViewDelegate

-(BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    //绘制轨迹
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        //创建要显示的折线
        BMKPolylineView *polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        //设置折线的填充颜色
        polylineView.fillColor = [UIColor greenColor];
        //设置折线的颜色
        polylineView.strokeColor = [UIColor greenColor];
        //设置折线的宽度
        polylineView.lineWidth = 3.0;
        return polylineView;
    }
    return nil;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    self.mapView.delegate = nil;
    self.locationService.delegate = nil;
    self.geoCodeSearch.delegate = nil;
    self.routeSearch.delegate = nil;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
