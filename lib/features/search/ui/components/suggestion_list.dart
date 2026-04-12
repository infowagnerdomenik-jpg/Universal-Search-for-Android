import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

class SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // --- DESIGN ENGINE FARBEN ---
    final Color esv = context.esurfacevariant; // ehemals cf2 (Surface)
    final Color eonbg = context.eonbackground; // ehemals txt1 (Text)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: esv, // Automatisch Surface-Variant
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            color: eonbg.withOpacity(0.1),
          ),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () { HapticFeedback.selectionClick(); onSelected(suggestion); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: eonbg.withOpacity(0.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            color: eonbg,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.north_west,
                        size: 16,
                        color: eonbg.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}