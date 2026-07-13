import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// 附近地点关键词搜索框。
///
/// 输入状态和校验收敛在独立组件内，是为了让首页与地图结果页复用完全一致的交互，
/// 同时避免页面状态同时承担文本控制、定位和网络请求三类职责。
class NearbySearchField extends StatefulWidget {
  const NearbySearchField({
    super.key,
    required this.onSubmitted,
    this.initialKeyword = '',
    this.enabled = true,
  });

  final ValueChanged<String> onSubmitted;
  final String initialKeyword;
  final bool enabled;

  @override
  State<NearbySearchField> createState() => _NearbySearchFieldState();
}

class _NearbySearchFieldState extends State<NearbySearchField> {
  static const int _maximumKeywordLength = 80;

  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
  }

  @override
  void didUpdateWidget(covariant NearbySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialKeyword != widget.initialKeyword &&
        _controller.text != widget.initialKeyword) {
      // 地图页完成一次新搜索后同步规范化关键词，确保重试和界面显示使用同一文本；
      // 光标放到末尾，避免用户继续编辑时跳回开头。
      _controller.value = TextEditingValue(
        text: widget.initialKeyword,
        selection: TextSelection.collapsed(
          offset: widget.initialKeyword.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      inputFormatters: [
        LengthLimitingTextInputFormatter(_maximumKeywordLength),
      ],
      onChanged: (value) {
        setState(() {
          if (value.trim().isNotEmpty) {
            _errorText = null;
          }
        });
      },
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: '搜索附近地点，如景点、咖啡馆',
        errorText: _errorText,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mint),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText)
              IconButton(
                onPressed: widget.enabled ? _clear : null,
                tooltip: '清空搜索内容',
                icon: const Icon(Icons.close_rounded),
              ),
            IconButton(
              onPressed: widget.enabled ? _submit : null,
              tooltip: '搜索附近地点',
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
        ),
      ),
    );
  }

  void _clear() {
    _controller.clear();
    setState(() => _errorText = null);
  }

  void _submit() {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) {
      setState(() => _errorText = '请输入搜索内容');
      return;
    }

    // 提交前把规范化结果回写到输入框，避免用户看到多余空格但请求使用另一份文本。
    _controller.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    setState(() => _errorText = null);
    widget.onSubmitted(keyword);
  }
}
