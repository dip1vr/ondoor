import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ondoor/theme/app_theme.dart';
import 'package:ondoor/widgets/genz_card.dart';

class ShimmerHelper {
  static Widget buildBasicShimmer({
    double? width,
    double? height,
    double radius = 12,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  static Widget buildStatsCardShimmer() {
    return Expanded(
      child: GenZCard(
        padding: const EdgeInsets.all(16),
        color: AppTheme.cardDark,
        child: Column(
          children: [
            buildBasicShimmer(width: 28, height: 28, radius: 8),
            const SizedBox(height: 10),
            buildBasicShimmer(width: 60, height: 24, radius: 4),
            const SizedBox(height: 4),
            buildBasicShimmer(width: 40, height: 14, radius: 4),
          ],
        ),
      ),
    );
  }

  static Widget buildActiveOrderCardShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GenZCard(
        color: AppTheme.cardDark,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildBasicShimmer(width: 120, height: 20, radius: 4),
                  buildBasicShimmer(width: 80, height: 24, radius: 20),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  buildBasicShimmer(width: 18, height: 18, radius: 4),
                  const SizedBox(width: 6),
                  buildBasicShimmer(width: 200, height: 16, radius: 4),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildBasicShimmer(width: 80, height: 12, radius: 4),
                      const SizedBox(height: 4),
                      buildBasicShimmer(width: 60, height: 24, radius: 4),
                    ],
                  ),
                  buildBasicShimmer(width: 32, height: 32, radius: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildListShimmer({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }

  static Widget buildLocationPageShimmer() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                buildBasicShimmer(width: 44, height: 44, radius: 12),
                const SizedBox(width: 16),
                buildBasicShimmer(width: 150, height: 24, radius: 4),
                const Spacer(),
                buildBasicShimmer(width: 80, height: 28, radius: 20),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Card
                  GenZCard(
                    color: AppTheme.cardDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildBasicShimmer(
                                  width: 140,
                                  height: 20,
                                  radius: 4,
                                ),
                                const SizedBox(height: 8),
                                buildBasicShimmer(
                                  width: 100,
                                  height: 14,
                                  radius: 4,
                                ),
                              ],
                            ),
                            buildBasicShimmer(
                              width: 40,
                              height: 40,
                              radius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            buildBasicShimmer(width: 20, height: 20, radius: 4),
                            const SizedBox(width: 12),
                            buildBasicShimmer(
                              width: 220,
                              height: 16,
                              radius: 4,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            buildBasicShimmer(width: 60, height: 16, radius: 4),
                            buildBasicShimmer(width: 60, height: 16, radius: 4),
                            buildBasicShimmer(width: 80, height: 24, radius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Steps
                  buildBasicShimmer(
                    width: double.infinity,
                    height: 100,
                    radius: 24,
                  ),
                  const SizedBox(height: 24),
                  // Button
                  buildBasicShimmer(
                    width: double.infinity,
                    height: 56,
                    radius: 16,
                  ),
                  const SizedBox(height: 24),
                  // Map
                  buildBasicShimmer(
                    width: double.infinity,
                    height: 250,
                    radius: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildEarningsHistoryShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GenZCard(
        color: AppTheme.cardDark,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              buildBasicShimmer(width: 40, height: 40, radius: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildBasicShimmer(width: 140, height: 16, radius: 4),
                    const SizedBox(height: 6),
                    buildBasicShimmer(width: 100, height: 12, radius: 4),
                  ],
                ),
              ),
              buildBasicShimmer(width: 60, height: 20, radius: 4),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildProfileShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SafeArea(bottom: false, child: SizedBox(height: 20)),
            // Header
            GenZCard(
              padding: const EdgeInsets.all(24),
              color: AppTheme.cardDark,
              child: Column(
                children: [
                  buildBasicShimmer(width: 100, height: 100, radius: 50),
                  const SizedBox(height: 16),
                  buildBasicShimmer(width: 150, height: 24, radius: 4),
                  const SizedBox(height: 8),
                  buildBasicShimmer(width: 200, height: 14, radius: 4),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          buildBasicShimmer(width: 40, height: 24, radius: 4),
                          const SizedBox(height: 4),
                          buildBasicShimmer(width: 60, height: 12, radius: 4),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.white10),
                      Column(
                        children: [
                          buildBasicShimmer(width: 40, height: 24, radius: 4),
                          const SizedBox(height: 4),
                          buildBasicShimmer(width: 60, height: 12, radius: 4),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Vehicle
            GenZCard(
              color: AppTheme.cardDark,
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 80,
                child: Row(
                  children: [
                    buildBasicShimmer(width: 40, height: 40, radius: 20),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildBasicShimmer(width: 120, height: 16, radius: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Bank
            GenZCard(
              color: AppTheme.cardDark,
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 80,
                child: Row(
                  children: [
                    buildBasicShimmer(width: 40, height: 40, radius: 20),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildBasicShimmer(width: 120, height: 16, radius: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Settings
            GenZCard(
              color: AppTheme.cardDark,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        buildBasicShimmer(width: 24, height: 24, radius: 4),
                        const SizedBox(width: 16),
                        buildBasicShimmer(width: 100, height: 16, radius: 4),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        buildBasicShimmer(width: 24, height: 24, radius: 4),
                        const SizedBox(width: 16),
                        buildBasicShimmer(width: 140, height: 16, radius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildUploadShimmer() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GenZCard(
        padding: const EdgeInsets.all(24),
        color: AppTheme.cardDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildBasicShimmer(width: 60, height: 60, radius: 30),
            const SizedBox(height: 20),
            buildBasicShimmer(width: 150, height: 20, radius: 4),
            const SizedBox(height: 12),
            buildBasicShimmer(width: 100, height: 14, radius: 4),
          ],
        ),
      ),
    );
  }

  static Widget buildEditFieldsShimmer() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildBasicShimmer(width: 100, height: 12, radius: 4),
              const SizedBox(height: 8),
              buildBasicShimmer(width: double.infinity, height: 48, radius: 12),
            ],
          ),
        ),
      ),
    );
  }
}
