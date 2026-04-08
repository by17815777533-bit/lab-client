import '../../models/gradpath_track.dart';

const List<GradPathTrackMeta> gradPathTracks = <GradPathTrackMeta>[
  GradPathTrackMeta(
    code: 'backend',
    name: '后端开发与服务架构',
    shortName: 'Backend',
    practiceKeyword: 'Java 基础',
    interviewPosition: '后端开发工程师',
    preferredLanguage: 'java',
  ),
  GradPathTrackMeta(
    code: 'frontend',
    name: '前端工程与用户体验',
    shortName: 'Frontend',
    practiceKeyword: 'Web 逻辑',
    interviewPosition: '前端开发工程师',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'ai',
    name: '人工智能与模型应用',
    shortName: 'AI',
    practiceKeyword: '动态规划',
    interviewPosition: '算法工程师',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'embedded',
    name: '嵌入式与物联网开发',
    shortName: 'Embedded',
    practiceKeyword: '数据结构',
    interviewPosition: '嵌入式工程师',
    preferredLanguage: 'c',
  ),
  GradPathTrackMeta(
    code: 'security',
    name: '网络安全与攻防实践',
    shortName: 'Security',
    practiceKeyword: '图搜索',
    interviewPosition: '安全工程师',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'bigdata',
    name: '大数据平台与数据工程',
    shortName: 'Big Data',
    practiceKeyword: '队列',
    interviewPosition: '大数据开发工程师',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'analysis',
    name: '数据分析与商业洞察',
    shortName: 'Analytics',
    practiceKeyword: 'Python',
    interviewPosition: '数据分析师',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'product',
    name: '产品策划与需求设计',
    shortName: 'Product',
    practiceKeyword: '逻辑表达',
    interviewPosition: '产品经理',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'design',
    name: 'UI/UX 设计与体验优化',
    shortName: 'Design',
    practiceKeyword: '交互设计',
    interviewPosition: '交互设计师',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'qa',
    name: '测试开发与质量保障',
    shortName: 'QA',
    practiceKeyword: '自动化测试',
    interviewPosition: '测试开发工程师',
    preferredLanguage: 'java',
  ),
  GradPathTrackMeta(
    code: 'cloud',
    name: '云平台与运维自动化',
    shortName: 'Cloud',
    practiceKeyword: '容器调度',
    interviewPosition: '云平台工程师',
    preferredLanguage: 'python',
  ),
  GradPathTrackMeta(
    code: 'game',
    name: '游戏开发与实时交互',
    shortName: 'Game',
    practiceKeyword: '实时交互',
    interviewPosition: '游戏客户端工程师',
    preferredLanguage: 'cpp',
  ),
];

GradPathTrackMeta resolveGradPathTrack(String? code) {
  return gradPathTracks.firstWhere(
    (GradPathTrackMeta item) => item.code == code,
    orElse: () => gradPathTracks.first,
  );
}
