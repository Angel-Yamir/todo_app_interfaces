import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  Future<void> logTaskCreated(String taskType) => _analytics.logEvent(
        name: 'task_created',
        parameters: {'task_type': taskType},
      );

  Future<void> logTaskCompleted(int daysToComplete) => _analytics.logEvent(
        name: 'task_completed',
        parameters: {'days_to_complete': daysToComplete},
      );

  Future<void> setUserPlan(String plan) =>
      _analytics.setUserProperty(name: 'plan', value: plan);
}
