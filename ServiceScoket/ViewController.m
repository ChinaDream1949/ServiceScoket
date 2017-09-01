//
//  ViewController.m
//  ServiceScoket
//
//  Created by 欧阳群峰 on 2017/9/1.
//  Copyright © 2017年 肖疆维. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
// 用于监听的socket
@property(nonatomic,strong)GCDAsyncSocket *listenSocket;
// 保存用于数据交互的socket (需要强引用 但是如果群聊需要多个强引用 所以建立数组)
@property(nonatomic,strong)NSMutableArray *connectedSockets;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)clickStartServer:(id)sender {
    // 绑定ip&监听端口&接收新连接封装在一个方法中
    BOOL success = [self.listenSocket acceptOnInterface:@"127.0.0.1" port:1234 error:nil];
    if (success) {
        NSLog(@"服务器开启成功");
    }else{
         NSLog(@"服务器开启失败");
    }
}

#pragma mark GCDAsyncSocketDelegate
/**
 *  已经接收到新的连接后调用
 *
 *  @param sock      服务端用于监听的socket
 *  @param newSocket 服务端用于数据交互的socket
 */
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
   
    NSLog(@"接收到来自%@的连接，其端口为%hu",newSocket.connectedHost,newSocket.connectedPort);
    [self.connectedSockets addObject:newSocket];
    // 设置欢迎信息
    NSString *str = [NSString stringWithFormat:@"欢迎连接我的MAC服务器"];
    [newSocket writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
//    // 定时器 轮询
//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(readData:) userInfo:newSocket repeats:YES];
//    // 开启异步线程runloop（因为接收socket为异步不会执行 NSTimer）
//    [[NSRunLoop currentRunLoop]run];
    // 接收数据
    [newSocket readDataWithTimeout:-1 tag:0];
}
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"已经发送出去");
}
//-(void)readData:(NSTimer *)obj{
//    // 接收数据
//    GCDAsyncSocket *socket = obj.userInfo;
//    [socket readDataWithTimeout:-1 tag:0];
//}
/**
 *  已经接收到的数据
 *
 *  @param sock 服务端用于数据交互的socket
 *  @param data 接收到的数据
 *  @param tag  标记
 */
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
    // 接收的数据
    [sock readDataWithTimeout:-1 tag:0];
    // 转发给指定用户
    for (GCDAsyncSocket *connetctedSocket in self.connectedSockets) {
        if (connetctedSocket != sock) {
            [connetctedSocket writeData:data withTimeout:-1 tag:0];
        }
    }
}
#pragma mark  懒加载
-(GCDAsyncSocket *)listenSocket{
    if (_listenSocket == nil) {
        _listenSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0) socketQueue:NULL];
    }
    return _listenSocket;
}
-(NSMutableArray *)connectedSockets{
    if (_connectedSockets == nil) {
        _connectedSockets = [NSMutableArray array];
    }
    return _connectedSockets;
}
@end
