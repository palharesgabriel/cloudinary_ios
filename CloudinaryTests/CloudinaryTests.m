//
//  CloudinaryTests.m
//  CloudinaryTests
//
//  Created by Tal Lev-Ami on 24/10/12.
//  Copyright (c) 2012 Cloudinary Ltd. All rights reserved.
//

#import "CloudinaryTests.h"
#import "Cloudinary.h"
#import "Transformation.h"

@implementation CloudinaryTests

- (void)setUp
{
    [super setUp];
    cloudinary = [[Cloudinary alloc] initWithUrl:@"cloudinary://a:b@test123"];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testParseCloudinaryUrlNoPrivateCdn
{
    Cloudinary *cloudinary2 = [[Cloudinary alloc] initWithUrl:@"cloudinary://abc:def@ghi"];
    NSDictionary *config = [cloudinary2 config];
    STAssertEqualObjects([config valueForKey:@"api_key"], @"abc", nil);
    STAssertEqualObjects([config valueForKey:@"api_secret"], @"def", nil);
    STAssertEqualObjects([config valueForKey:@"cloud_name"], @"ghi", nil);
    STAssertEqualObjects([config valueForKey:@"private_cdn"], [NSNumber numberWithBool:NO], nil);
}

- (void)testParseCloudinaryUrlWithPrivateCdn
{
    Cloudinary *cloudinary2 = [[Cloudinary alloc] initWithUrl:@"cloudinary://abc:def@ghi/jkl"];
    NSDictionary *config = [cloudinary2 config];
    STAssertEqualObjects([config valueForKey:@"api_key"], @"abc", nil);
    STAssertEqualObjects([config valueForKey:@"api_secret"], @"def", nil);
    STAssertEqualObjects([config valueForKey:@"cloud_name"], @"ghi", nil);
    STAssertEqualObjects([config valueForKey:@"private_cdn"], [NSNumber numberWithBool:YES], nil);
    STAssertEqualObjects([config valueForKey:@"secure_distribution"], @"jkl", nil);
}

- (void) testCloudName {
    // should use cloud_name from config
    NSString* result = [cloudinary url:@"test"];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/test", result, nil);
}


- (void) testCloudNameOptions {
    // should allow overriding cloud_name in options
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:@"test321" forKey:@"cloud_name"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test321/image/upload/test", result, nil);
}

- (void) testSecureDistribution {
    // should use default secure distribution if secure=TRUE
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"secure"]];
    STAssertEqualObjects(@"https://d3jpl91pxevbkh.cloudfront.net/test123/image/upload/test", result, nil);
}

- (void) testSecureDistributionOverwrite {
    // should allow overwriting secure distribution if secure=TRUE
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"secure",
                                                         @"something.else.com", @"secure_distribution", nil]];
    STAssertEqualObjects(@"https://something.else.com/test123/image/upload/test", result, nil);
}

- (void) testSecureDistibution {
    // should take secure distribution from config if secure=TRUE
    [cloudinary.config setValue:@"config.secure.distribution.com" forKey:@"secure_distribution"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"secure"]];
    STAssertEqualObjects(@"https://config.secure.distribution.com/test123/image/upload/test", result, nil);
}

- (void) testMissingSecureDistribution {
    // should raise exception if secure is given with private_cdn and no
    // secure_distribution
    [cloudinary.config setValue:[NSNumber numberWithBool:YES] forKey:@"private_cdn"];
    NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"secure"];
    STAssertThrowsSpecificNamed([cloudinary url:@"test" options:options], NSException, @"ArgumentException", nil);
}

- (void) testFormat {
    // should use format from options
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:@"jpg" forKey:@"format"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/test.jpg", result, nil);
}


- (void) testCrop {
    Transformation* transformation = [Transformation transformation];
    [transformation iwidth:100];
    [transformation iheight:101];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/h_101,w_100/test", result, nil);
    STAssertEqualObjects(@"101", transformation.htmlHeight, nil);
    STAssertEqualObjects(@"100", transformation.htmlWidth, nil);
    transformation = [Transformation transformation];
    [transformation iwidth:100];
    [transformation iheight:101];
    [transformation crop:@"crop"];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/c_crop,h_101,w_100/test", result, nil);
}


- (void) testVariousOptions {
    // should use x, y, radius, prefix, gravity and quality from options
    Transformation* transformation = [Transformation transformation];
    [transformation ix:1];
    [transformation iy:2];
    [transformation iradius:3];
    [transformation gravity:@"center"];
    [transformation fquality:0.4];
    [transformation prefix:@"a"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/g_center,p_a,q_0.4,r_3,x_1,y_2/test", result, nil);
}


- (void) testTransformationSimple {
    // should support named transformation
    Transformation* transformation = [Transformation transformation];
    [transformation named:@"blip"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/t_blip/test", result, nil);
}


- (void) testTransformationArray {
    // should support array of named transformations
    Transformation* transformation = [Transformation transformation];
    [transformation named:[NSArray arrayWithObjects:@"blip", @"blop",nil]];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/t_blip.blop/test", result, nil);
}


- (void) testBaseTransformations {
    // should support base transformation
    Transformation* transformation = [Transformation transformation];
    [transformation ix:100];
    [transformation iy:100];
    [transformation crop:@"fill"];
    [transformation chain];
    [transformation crop:@"crop"];
    [transformation iwidth:100];

    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"100", transformation.htmlWidth, nil);
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/c_fill,x_100,y_100/c_crop,w_100/test", result, nil);
}


- (void) testBaseTransformationArray {
    // should support array of base transformations
    Transformation* transformation = [Transformation transformation];
    [transformation ix:100];
    [transformation iy:100];
    [transformation iwidth:200];
    [transformation crop:@"fill"];
    [transformation chain];
    [transformation iradius:10];
    [transformation chain];
    [transformation crop:@"crop"];
    [transformation iwidth:100];

    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"100", transformation.htmlWidth, nil);
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/c_fill,w_200,x_100,y_100/r_10/c_crop,w_100/test", result, nil);
}


- (void) testNoEmptyTransformation {
    // should not include empty transformations
    Transformation* transformation = [Transformation transformation];
    [transformation ix:100];
    [transformation iy:100];
    [transformation crop:@"fill"];
    [transformation chain];

    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/c_fill,x_100,y_100/test", result, nil);
}


- (void) testType {
    // should use type from options
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:@"facebook" forKey:@"type"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/facebook/test", result, nil);
}


- (void) testResourceType {
    // should use resource_type from options
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:@"raw" forKey:@"resource_type"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/raw/upload/test", result, nil);
}


- (void) testIgnoreHttp {
    // should ignore http links only if type is not given or is asset
    NSString* result = [cloudinary url:@"http://test"];
    STAssertEqualObjects(@"http://test", result, nil);
    result = [cloudinary url:@"http://test" options:[NSDictionary dictionaryWithObject:@"asset" forKey:@"type"]];
    STAssertEqualObjects(@"http://test", result, nil);
    result = [cloudinary url:@"http://test" options:[NSDictionary dictionaryWithObject:@"fetch" forKey:@"type"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/fetch/http://test", result, nil);
}


- (void) testFetch {
    // should escape fetch urls
    NSString* result = [cloudinary url:@"http://blah.com/hello?a=b" options:[NSDictionary dictionaryWithObject:@"fetch" forKey:@"type"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/fetch/http://blah.com/hello%3Fa%3Db", result, nil);
}


- (void) testCname {
    // should support extenal cname
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:@"hello.com" forKey:@"cname"]];
    STAssertEqualObjects(@"http://hello.com/test123/image/upload/test", result, nil);
}


- (void) testCnameSubdomain {
    // should support extenal cname with cdn_subdomain on
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObjectsAndKeys:@"hello.com", @"cname", [NSNumber numberWithInt:YES], @"cdn_subdomain", nil]];
    STAssertEqualObjects(@"http://a2.hello.com/test123/image/upload/test", result, nil);
}


- (void) testHttpEscape {
    // should escape http urls
    NSString* result = [cloudinary url:@"http://www.youtube.com/watch?v=d9NF2edxy-M" options:[NSDictionary dictionaryWithObject:@"youtube" forKey:@"type"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/youtube/http://www.youtube.com/watch%3Fv%3Dd9NF2edxy-M", result, nil);
}


- (void) testBackground {
    // should support background
    Transformation* transformation = [Transformation transformation];
    [transformation background:@"red"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/b_red/test", result, nil);
    transformation = [Transformation transformation];
    [transformation background:@"#112233"];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/b_rgb:112233/test", result, nil);
}


- (void) testDefaultImage {
    // should support default_image
    Transformation* transformation = [Transformation transformation];
    [transformation defaultImage:@"default"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/d_default/test", result, nil);
}


- (void) testAngle {
    // should support angle
    Transformation* transformation = [Transformation transformation];
    [transformation iangle:12];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/a_12/test", result, nil);
    transformation = [Transformation transformation];
    [transformation angle:[NSArray arrayWithObjects:@"exif", @"12", nil]];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/a_exif.12/test", result, nil);
}


- (void) testOverlay {
    // should support overlay
    Transformation* transformation = [Transformation transformation];
    [transformation overlay:@"text:hello"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/l_text:hello/test", result, nil);
    // should not pass width/height to html if overlay
    transformation = [Transformation transformation];
    [transformation overlay:@"text:hello"];
    [transformation width:@"100"];
    [transformation height:@"100"];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertNil(transformation.htmlHeight, nil);
    STAssertNil(transformation.htmlWidth, nil);
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/h_100,l_text:hello,w_100/test", result, nil);
}


- (void) testUnderlay {
    Transformation* transformation = [Transformation transformation];
    [transformation underlay:@"text:hello"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/u_text:hello/test", result, nil);
    // should not pass width/height to html if overlay
    transformation = [Transformation transformation];
    [transformation underlay:@"text:hello"];
    [transformation width:@"100"];
    [transformation height:@"100"];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertNil(transformation.htmlHeight, nil);
    STAssertNil(transformation.htmlWidth, nil);
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/h_100,u_text:hello,w_100/test", result, nil);
}


- (void) testFetchFormat {
    // should support format for fetch urls
    NSString* result = [cloudinary url:@"http://cloudinary.com/images/logo.png" options:[NSDictionary dictionaryWithObjectsAndKeys:@"fetch", @"type", @"jpg", @"format", nil]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/fetch/f_jpg/http://cloudinary.com/images/logo.png", result, nil);
}


- (void) testEffect {
    // should support effect
    Transformation* transformation = [Transformation transformation];
    [transformation effect:@"sepia"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/e_sepia/test", result, nil);
}


- (void) testEffectWithParam {
    // should support effect with param
    Transformation* transformation = [Transformation transformation];
    [transformation effect:@"sepia" param:[NSNumber numberWithInt:10]];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/e_sepia:10/test", result, nil);
}


- (void) testDensity {
    // should support density
    Transformation* transformation = [Transformation transformation];
    [transformation idensity:150];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/dn_150/test", result, nil);
}


- (void) testPage {
    // should support page
    Transformation* transformation = [Transformation transformation];
    [transformation ipage:5];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/pg_5/test", result, nil);
}


- (void) testBorder {
    // should support border
    Transformation* transformation = [Transformation transformation];
    [transformation border:5 color:@"black"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/bo_5px_solid_black/test", result, nil);
    transformation = [Transformation transformation];
    [transformation border:5 color:@"#ffaabbdd"];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/bo_5px_solid_rgb:ffaabbdd/test", result, nil);
    transformation = [Transformation transformation];
    [transformation border:@"1px_solid_blue"];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/bo_1px_solid_blue/test", result, nil);
}


- (void) testFlags {
    // should support flags
    Transformation* transformation = [Transformation transformation];
    [transformation flags:@"abc"];
    NSString* result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/fl_abc/test", result, nil);
    transformation = [Transformation transformation];
    [transformation flags:[NSArray arrayWithObjects:@"abc", @"def", nil]];
    result = [cloudinary url:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"]];
    STAssertEqualObjects(@"http://res.cloudinary.com/test123/image/upload/fl_abc.def/test", result, nil);
}


- (void) testImageTag {
    Transformation* transformation = [Transformation transformation];
    [transformation iwidth:100];
    [transformation iheight:101];
    [transformation crop:@"crop"];
    
    NSString* result = [cloudinary imageTag:@"test" options:[NSDictionary dictionaryWithObject:transformation forKey:@"transformation"] htmlOptions:[NSDictionary dictionaryWithObject:@"my image" forKey:@"alt"]];
    STAssertEqualObjects(@"<img src='http://res.cloudinary.com/test123/image/upload/c_crop,h_101,w_100/test' alt='my image' width='100' height='101'/>", result, nil);
}

- (void) testSignature {
    NSString* sig = [cloudinary apiSignRequest:[NSDictionary dictionaryWithObjectsAndKeys:@"b", @"a", @"d", @"c", @"", @"e", nil] secret:@"abcd"];
    STAssertEqualObjects(sig, @"ef1f04e0c1af08208a3dd28483107bc7f4a61209", nil);
}


@end
