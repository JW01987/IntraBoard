import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:file_picker/file_picker.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../utils/responsive.dart';

class WriteScreen extends StatefulWidget {
  final String boardType;
  final String? postId;

  const WriteScreen({super.key, required this.boardType, this.postId});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final quill.QuillController _quillController = quill.QuillController.basic();

  bool _isLoading = false;
  bool _isFetchingMocks = false;
  bool _isUploadingFiles = false;

  final List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (result != null) {
        if (!mounted) return;
        setState(() {
          for (var file in result.files) {
            if (file.size > 50 * 1024 * 1024) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${file.name}은(는) 50MB를 초과하여 제외되었습니다.')),
              );
              continue;
            }
            if (!_selectedFiles.any((e) => e.name == file.name && e.size == file.size)) {
              _selectedFiles.add(file);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("File Pick Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return [];

    setState(() => _isUploadingFiles = true);
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/files/upload');
    final headers = ApiConfig.getHeaders(context.read<UserProvider>().sessionCookie);
    List<Map<String, dynamic>> uploadedData = [];

    try {
      for (var file in _selectedFiles) {
        final req = http.MultipartRequest('POST', uri);
        req.headers.addAll(headers);
        if (file.bytes != null) {
          req.files.add(http.MultipartFile.fromBytes('files', file.bytes!, filename: file.name));
        }

        final streamedResponse = await req.send();
        if (!mounted) return [];
        final response = await http.Response.fromStream(streamedResponse);
        if (!mounted) return [];

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] != null) {
            final List list = body['data'];
            for (var item in list) {
              uploadedData.add(item as Map<String, dynamic>);
            }
          }
        } else {
          throw Exception("File upload failed with status ${response.statusCode}");
        }
      }
      return uploadedData;
    } finally {
      if (mounted) setState(() => _isUploadingFiles = false);
    }
  }

  // 이슈 전용 드롭다운 목록
  List<Map<String, dynamic>> _categories = [];
  List<UserModel> _staffList = [];

  int? _selectedCategory;
  int? _selectedPriority = 2; // 기본값: 보통
  int? _selectedStaff;
  int? _selectedStatus; // 수정 시 기존 statusId 유지
  bool _editDataLoaded = false; // 수정 데이터가 먼저 로드됐는지 추적

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      // 수정 모드: 기존 데이터를 먼저 로드 후 의존성 데이터 로드
      _fetchPostDetail().then((_) {
        if (widget.boardType == 'ISSUE') _fetchIssueDependencies();
      });
    } else {
      // 신규 작성: 의존성 데이터만 로드
      if (widget.boardType == 'ISSUE') _fetchIssueDependencies();
    }
  }

  Future<void> _fetchPostDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/${widget.postId}'),
        headers: ApiConfig.getHeaders(context.read<UserProvider>().sessionCookie),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        setState(() {
          _titleController.text = data['title'] ?? '';
          _selectedCategory = data['categoryId'];
          _selectedPriority = data['priority'] ?? 2;
          _selectedStaff = data['assignedUserId'];
          _selectedStatus = data['statusId']; // 기존 상태값 저장
          _editDataLoaded = true;
          
          // Quill 에디터 내용 주입 (HTML -> QuillDelta)
          if (data['content'] != null) {
             final plainText = data['content']
                .replaceAll(RegExp(r'</p>|<br\s*/?>'), '\n')
                .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '');
             _quillController.document = quill.Document.fromDelta(Delta()..insert(plainText));
          }
        });
      }
    } catch (e) {
      debugPrint('Fetch Detail Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchIssueDependencies() async {
    setState(() => _isFetchingMocks = true);
    final headers =
        ApiConfig.getHeaders(context.read<UserProvider>().sessionCookie);

    try {
      // 카테고리
      final catRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/system/categories'),
          headers: headers);
      if (!mounted) return;
      if (catRes.statusCode == 200) {
        final List list = jsonDecode(catRes.body)['data'];
        _categories = list.map((e) => e as Map<String, dynamic>).toList();
        // 수정 모드에서 기존 데이터가 이미 로드됐다면 카테고리를 첫 번째 값으로 덮어쓰지 않음
        if (!_editDataLoaded && _categories.isNotEmpty) {
          _selectedCategory = _categories.first['categoryId'];
        }
      }

      // 담당자 목록 (본사 직원)
      final staffRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/users/staff'),
          headers: headers);
      if (!mounted) return;
      if (staffRes.statusCode == 200) {
        final List list = jsonDecode(staffRes.body)['data'];
        _staffList = list.map((e) => UserModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dependencies: $e');
    } finally {
      if (mounted) setState(() => _isFetchingMocks = false);
    }
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }

    // Quill Delta를 HTML로 변환
    final deltaJson = _quillController.document.toDelta().toJson();
    final converter = QuillDeltaToHtmlConverter(
        List.castFrom(deltaJson), ConverterOptions.forEmail());
    final htmlContent = converter.convert();

    if (htmlContent.trim().isEmpty || htmlContent == '<p><br/></p>') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('본문을 입력해주세요.')));
      return;
    }

    if (widget.boardType == 'ISSUE' && _selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> uploadedFiles = [];
      if (_selectedFiles.isNotEmpty) {
        uploadedFiles = await _uploadFiles();
        if (!mounted) return;
      }

      final payload = {
        'boardType': widget.boardType,
        'title': _titleController.text.trim(),
        'content': htmlContent,
        'categoryId': _selectedCategory,
        'priority': _selectedPriority,
        'assignedUserId': _selectedStaff,
        // 수정 모드: 기존 statusId 유지, 신규 작성: null (백엔드 기본값 적용)
        if (_selectedStatus != null) 'statusId': _selectedStatus,
        'files': uploadedFiles,
      };

      final url = widget.postId != null 
          ? '${ApiConfig.baseUrl}/api/posts/${widget.postId}'
          : '${ApiConfig.baseUrl}/api/posts';

      final res = widget.postId != null
          ? await http.put(Uri.parse(url),
              headers: ApiConfig.getHeaders(context.read<UserProvider>().sessionCookie),
              body: jsonEncode(payload))
          : await http.post(Uri.parse(url),
              headers: ApiConfig.getHeaders(context.read<UserProvider>().sessionCookie),
              body: jsonEncode(payload));
      
      if (!mounted) return;

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.postId != null ? '게시글이 수정되었습니다.' : '게시글이 성공적으로 등록되었습니다.')));
          context.pop(true); // 목록으로 이동하며 true 반환
        }
      } else {
        final errorData = jsonDecode(res.body);
        throw Exception(errorData['message'] ?? '알 수 없는 서버 오류가 발생했습니다.');
      }
    } catch (e) {
      debugPrint('Submit Post Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('글 작성 실패: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = widget.postId != null ? '글 수정' : '글 쓰기';
    if (widget.boardType == 'NOTICE') titleText = widget.postId != null ? '공지사항 수정' : '공지사항 작성';
    if (widget.boardType == 'ISSUE') titleText = widget.postId != null ? '이슈/문의 수정' : '이슈/문의 작성';
    if (widget.boardType == 'ARCHIVE') titleText = widget.postId != null ? '자료실 수정' : '자료실 업로드';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity, // 가로를 가득 채우되 MaxWidth로 제한
          constraints:
              context.isMobile ? null : const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 영역 (배경색을 입혀 스크롤 시 앱바와 겹쳐보이는 현상 방지)
                      Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: '제목을 입력하세요',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ),
                      const Divider(),

                      // 옵션 (이슈 전용)
                      if (widget.boardType == 'ISSUE') ...[
                        const SizedBox(height: 16),
                        if (_isFetchingMocks)
                          const Center(child: CircularProgressIndicator())
                        else
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildDropdown<int>(
                                label: '카테고리',
                                value: _selectedCategory,
                                items: _categories
                                    .map((c) => DropdownMenuItem<int>(
                                        value: c['categoryId'],
                                        child: Text(c['categoryName'])))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCategory = v),
                              ),
                              _buildDropdown<int>(
                                label: '중요도',
                                value: _selectedPriority,
                                items: const [
                                  DropdownMenuItem(value: 4, child: Text('긴급')),
                                  DropdownMenuItem(value: 3, child: Text('높음')),
                                  DropdownMenuItem(value: 2, child: Text('보통')),
                                  DropdownMenuItem(value: 1, child: Text('낮음')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedPriority = v),
                              ),
                              _buildDropdown<int?>(
                                label: '담당자 지정',
                                value: _selectedStaff,
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('선택 안함')),
                                  ..._staffList.map((s) => DropdownMenuItem<
                                          int>(
                                      value: s.userId,
                                      child: Text(
                                          '${s.name} (${s.companyName ?? "본사"})'))),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedStaff = v),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        const Divider(),
                      ],

                      // 에디터 툴바
                      const SizedBox(height: 16),
                      quill.QuillToolbar.simple(
                        configurations: quill.QuillSimpleToolbarConfigurations(
                          controller: _quillController,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showSearchButton: false,
                          showSubscript: false,
                          showSuperscript: false,
                          showInlineCode: false,
                          showIndent: false,
                          showAlignmentButtons: false,
                          showClearFormat: false,
                          sharedConfigurations:
                              const quill.QuillSharedConfigurations(
                            locale: Locale('ko', 'KR'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 에디터 본문
                      Container(
                        constraints: const BoxConstraints(minHeight: 400),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: quill.QuillEditor.basic(
                          configurations: quill.QuillEditorConfigurations(
                            controller: _quillController,
                            scrollable: false, // 자체 스크롤을 끄고 부모의 SingleChildScrollView를 따르게 함
                            sharedConfigurations:
                                const quill.QuillSharedConfigurations(
                              locale: Locale('ko', 'KR'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 파일 첨부 영역
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _isUploadingFiles ? null : _pickFiles,
                            icon: const Icon(LucideIcons.paperclip, size: 18),
                            label: const Text('파일 첨부'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(120, 48), // 전역 테마의 infinity width 덮어쓰기
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('최대 50MB, 다중 선택 가능', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      if (_isUploadingFiles)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator(),
                        ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _selectedFiles.map((file) {
                              bool isImage = file.extension == 'jpg' || file.extension == 'jpeg' || file.extension == 'png' || file.extension == 'gif';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    if (isImage && file.bytes != null)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          image: DecorationImage(image: MemoryImage(file.bytes!), fit: BoxFit.cover)
                                        ),
                                      )
                                    else
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(LucideIcons.file, size: 24, color: Colors.grey),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                                          Text('${(file.size / 1024 / 1024).toStringAsFixed(2)} MB', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.x, size: 18, color: Colors.red),
                                      onPressed: _isUploadingFiles ? null : () => setState(() => _selectedFiles.remove(file)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
              // 하단 등록 버튼 영역 (모바일 중첩 AppBar 이슈 대응 및 가시성 확보)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _submitPost,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(LucideIcons.check),
                    label: Text(widget.postId != null ? '수정 완료' : '게시글 등록하기',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
