import 'package:flutter/material.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/course_set_view_model.dart';

class SearchField extends StatelessWidget {
  final WriteCourseSetViewModel vm;

  const SearchField({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: vm.layerLink,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: vm.searchController,
              focusNode: vm.searchFocus,
              onChanged: (v) {
                vm.fetchKakaoSuggestions(v);

                // 오버레이 표시
                if (vm.searchResults.isNotEmpty) {
                  vm.showOverlay(context, _buildOverlay(context));
                } else {
                  vm.hideOverlay();
                }
              },
              decoration: const InputDecoration(
                hintText: "주소나 매장명 검색",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => vm.manualSearch(),
            child: const Text("검색"),
          ),
        ],
      ),
    );
  }

  /// ---------- Overlay UI ----------
  Widget _buildOverlay(BuildContext context) {
    return Positioned.fill(
      child: CompositedTransformFollower(
        link: vm.layerLink,
        offset: const Offset(0, 50),
        showWhenUnlinked: false,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: vm.searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = vm.searchResults[i];

                return ListTile(
                  title: Text(item["name"]),
                  subtitle: Text(item["address"] ?? ""),
                  onTap: () {
                    vm.hideOverlay();
                    FocusScope.of(context).unfocus();

                    vm.searchController.text = item["name"];
                    vm.onSearchRequested?.call(item["name"]);
                    vm.onLocationSaved?.call(item["lat"], item["lng"]);
                    vm.onShowMapRequested?.call();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
