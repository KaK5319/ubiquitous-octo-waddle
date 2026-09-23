// StackおよびTransformを用いたスライド影の補正部分
return AnimatedBuilder(
  animation: _pageController,
  builder: (context, child) {
    double position = 0.0;
    if (_pageController.position.haveDimensions) {
      position = (index - (_pageController.page ?? 0));
    } else {
      position = (index - _currentPage).toDouble();
    }

    // めくられている最中のページ（0.0 〜 1.0）
    final isCurrent = index == _currentPage;
    final shadowProgress = (1.0 - position.abs()).clamp(0.0, 1.0);

    return Stack(
      children: [
        child!,
        // ページ移動時にのみ現れる立体的なドロップシャドウ
        if (position != 0)
          Positioned(
            top: 0,
            bottom: 0,
            // 右開き/左開きに応じて影の位置を切り替え
            left: _isRightSwipe ? 0 : null,
            right: _isRightSwipe ? null : 0,
            width: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: _isRightSwipe ? Alignment.centerLeft : Alignment.centerRight,
                  end: _isRightSwipe ? Alignment.centerRight : Alignment.centerLeft,
                  colors: [
                    Colors.black.withOpacity(0.4 * shadowProgress),
                    Colors.black.withOpacity(0.1 * shadowProgress),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  },
  child: GestureDetector(
    // ...タップ処理...
  ),
);
