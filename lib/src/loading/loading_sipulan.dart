import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget ShimmerLoadingSipulan() {
  return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child:
        Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Column(
          children: [
            Card(
              elevation: 10,
              child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 30,
                                        ),
                                        const SizedBox(
                                          height: 25.0,
                                        ),
                                        Container(height: 30,),
                                        Container(height: 30,),
                                        const SizedBox(
                                          height: 8.0,
                                        ),
                                        Container(),
                                        Container(),
                                        const SizedBox(
                                          height: 8.0,
                                        ),
                                        Container(),
                                        Container(),
                                        const SizedBox(
                                          height: 8.0,
                                        ),
                                        Container(),
                                        Container(),
                                        const SizedBox(
                                          height: 8.0,
                                        ),
                                        Container(),
                                        Container(),
                                        const SizedBox(
                                          height: 8.0,
                                        ),
                                        Container(),
                                        Container(),
                                        const SizedBox(
                                          height: 8.0,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                        ],
                      ))),
            ),
          ],
        ))    
      ]),
    );
}