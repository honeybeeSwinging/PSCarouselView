//
//  CarouselView.m
//
//  Created by Pan on 15/7/20.
//  Copyright (c) 2015年 Pan. All rights reserved.
//

#define SCREEN_HEIGHT           [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH            [UIScreen mainScreen].bounds.size.width
#define REUSE_IDENTIFIER        [PSCarouselCollectionCell description]

#import "PSCarouselView.h"
#import "PSCarouselCollectionCell.h"
#import "UIImageView+WebCache.h"

@interface PSCarouselView()<UICollectionViewDelegate,
                            UICollectionViewDataSource,
                            UICollectionViewDelegateFlowLayout>


@property (nonatomic, strong) NSTimer *timer;


@end

@implementation PSCarouselView
@synthesize imageURLs = _imageURLs;

#pragma mark - Life Cycle

- (void)awakeFromNib
{
    self.delegate = self;
    self.dataSource = self;
    self.pagingEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    if ([self.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]])
    {
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
    }
    [self registerNib:[UINib nibWithNibName:REUSE_IDENTIFIER bundle:nil] forCellWithReuseIdentifier:REUSE_IDENTIFIER];
    [self registerNofitication];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Public Method

- (void)startMoving
{
    [self addTimer];
}

- (void)stopMoving
{
    [self removeTimer];
}


#pragma mark - Private Method


- (void)addTimer
{
    [self removeTimer];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(moveToNextPage) userInfo:nil repeats:YES];
}

- (void)removeTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)moveToNextPage
{
    CGPoint newContentOffset = (CGPoint){self.contentOffset.x + SCREEN_WIDTH,0};
    [self setContentOffset:newContentOffset animated:YES];
}

- (void)adjustCurrentPage:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x / SCREEN_WIDTH - 1;
    
    if (scrollView.contentOffset.x < SCREEN_WIDTH)
    {
        page = [self.imageURLs count] - 3;
    }
    else if (scrollView.contentOffset.x > SCREEN_WIDTH * ([self.imageURLs count] - 1))
    {
        page = 0;
    }
    if ([self.pageDelegate respondsToSelector:@selector(carousel:didMoveToPage:)])
    {
        [self.pageDelegate carousel:self didMoveToPage:page];
    }
}

- (void)registerNofitication
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackGround) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForGround) name:UIApplicationWillEnterForegroundNotification object:nil];
}


#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return MAX([self.imageURLs count],1);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PSCarouselCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:REUSE_IDENTIFIER forIndexPath:indexPath];
    
    if (![self.imageURLs count])
    {
        [cell.adImageView setImage:[UIImage imageNamed:@"home_banner_loding"]];
        return cell;
    }
    [cell.adImageView sd_setImageWithURL:[self.imageURLs objectAtIndex:indexPath.item] placeholderImage:self.placeholder];

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.frame.size.width, self.frame.size.height);
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger page = 0;
    NSUInteger lastIndex = [self.imageURLs count] - 3;
    
    if (indexPath.item == 0)
    {
        page = lastIndex;
    }
    else if (indexPath.item == lastIndex)
    {
        page = 0;
    }
    else
    {
        page = indexPath.item - 1;
    }
    if ([self.pageDelegate respondsToSelector:@selector(carousel:didTouchPage:)])
    {
        [self.pageDelegate carousel:self didTouchPage:page];
    }
}


#pragma mark - UIScrollerViewDelegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x == ([self.imageURLs count] - 1) * SCREEN_WIDTH )
    {
        [self setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:NO];
    }
    
    //轮播滚动的时候 移动到了哪一页
    [self adjustCurrentPage:scrollView];
    
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self removeTimer];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.isAutoMoving)
    {
        [self addTimer];
    }
    
    //向左滑动时切换imageView
    if (scrollView.contentOffset.x < SCREEN_WIDTH )
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.imageURLs count] - 2 inSection:0];
        [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
    
    //向右滑动时切换imageView
    if (scrollView.contentOffset.x  > ([self.imageURLs count] - 1) * SCREEN_WIDTH - 10)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
        [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
    
    //用户手动拖拽的时候 移动到了哪一页
    [self adjustCurrentPage:scrollView];

}


#pragma mark - Notification

- (void)applicationDidEnterBackGround
{
    [self stopMoving];
}

- (void)applicationWillEnterForGround
{
    if (self.isAutoMoving)
    {
        [self startMoving];
    }
}


#pragma mark - Getter and Setter

- (NSArray *)imageURLs
{
    if (!_imageURLs)
    {
        _imageURLs = [NSArray array];
    }
    return _imageURLs;
}

- (void)setImageURLs:(NSArray *)imageURLs
{
    _imageURLs = imageURLs;
    if ([imageURLs count])
    {
        NSMutableArray *arr = [NSMutableArray array];
        [arr addObject:[imageURLs lastObject]];
        [arr addObjectsFromArray:imageURLs];
        [arr addObject:[imageURLs firstObject]];
        _imageURLs = [NSArray arrayWithArray:arr];
    }
    [self reloadData];
    //最左边一张图其实是最后一张图，因此移动到第二张图，也就是imageURL的第一个URL的图。
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}
@end
