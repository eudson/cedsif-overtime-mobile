import 'package:cedsif_overtime_mobile/features/home/data/models/home_content_model.dart';

class HomeLocalDataSource {
  const HomeLocalDataSource();

  Future<HomeContentModel> getContent() async =>
      const HomeContentModel(translationKey: 'home.placeholder');
}
