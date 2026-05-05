import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';

class BoardScreen extends StatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _dbService = DatabaseService();
  final _nameController = TextEditingController();
  final _taskLinkController = TextEditingController();

  String? _userName;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('magic_fix_user_name');
      _userRole = prefs.getString('magic_fix_user_role');
      _isLoading = false;
    });
  }

  Future<void> _saveProfile(String name, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('magic_fix_user_name', name);
    await prefs.setString('magic_fix_user_role', role);
    setState(() {
      _userName = name;
      _userRole = role;
    });
  }

  Future<void> _clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('magic_fix_user_name');
    await prefs.remove('magic_fix_user_role');
    setState(() {
      _userName = null;
      _userRole = null;
    });
  }

  bool get _isMagicFixUser => _userRole == 'magic_fix';
  bool get _isSetUp => _userName != null && _userRole != null;

  String get _shareableLink {
    final uri = Uri.base;
    final base = '${uri.scheme}://${uri.host}';
    final port = (uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
    return '$base$port/board/${widget.boardId}';
  }

  void _copyShareableLink() {
    Clipboard.setData(ClipboardData(text: _shareableLink));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Board link copied to clipboard!')),
    );
  }

  void _quickAddTask() {
    final link = _taskLinkController.text.trim();
    if (link.isEmpty) return;
    _dbService.addTask(
      boardId: widget.boardId,
      link: link,
      createdBy: _userName!,
    );
    _taskLinkController.clear();
  }

  void _completeTask(String taskId) {
    _dbService.completeTask(
      boardId: widget.boardId,
      taskId: taskId,
      completedBy: _userName!,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taskLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isSetUp) {
      return _buildSetupScreen();
    }

    return _buildBoardScreen();
  }

  // ── Setup Screen ──────────────────────────────────────────────────────

  Widget _buildSetupScreen() {
    final theme = Theme.of(context);
    String selectedRole = 'regular';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: StatefulBuilder(
              builder: (context, setLocalState) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join Board',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Board: ${widget.boardId}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Select your role', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'regular',
                        label: Text('Regular'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: 'magic_fix',
                        label: Text('Magic Fix'),
                        icon: Icon(Icons.auto_fix_high),
                      ),
                    ],
                    selected: {selectedRole},
                    onSelectionChanged: (value) {
                      setLocalState(() => selectedRole = value.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedRole == 'regular'
                        ? 'You can create tasks with shareable links.'
                        : 'You can mark tasks as done.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your name.'),
                            ),
                          );
                          return;
                        }
                        _saveProfile(name, selectedRole);
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Board Screen ──────────────────────────────────────────────────────

  Widget _buildBoardScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Magic Fix'),
          ],
        ),
        actions: [
          ActionChip(
            avatar: const Icon(Icons.share, size: 16),
            label: Text(widget.boardId),
            onPressed: _copyShareableLink,
          ),
          const SizedBox(width: 8),
          Chip(
            avatar: Icon(
              _isMagicFixUser ? Icons.auto_fix_high : Icons.person,
              size: 16,
            ),
            label: Text(_userName ?? ''),
            backgroundColor: _isMagicFixUser
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Change profile',
            onPressed: _clearProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _dbService.tasksStream(widget.boardId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load tasks',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          final pendingTasks = tasks.where((t) => t.isPending).toList();
          final doneTasks = tasks.where((t) => t.isDone).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 768) {
                return _buildWideLayout(pendingTasks, doneTasks);
              }
              return _buildNarrowLayout(pendingTasks, doneTasks);
            },
          );
        },
      ),
      bottomNavigationBar: !_isMagicFixUser
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ).copyWith(bottom: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskLinkController,
                        decoration: InputDecoration(
                          hintText: 'Paste shareable link here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(Icons.link),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _quickAddTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _quickAddTask,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ── Layout helpers ────────────────────────────────────────────────────

  Widget _buildWideLayout(List<TaskModel> pending, List<TaskModel> done) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildColumn(
              'Pending',
              pending,
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildColumn(
              'Completed',
              done,
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(List<TaskModel> pending, List<TaskModel> done) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Completed (${done.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildTaskList(pending), _buildTaskList(done)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    String title,
    List<TaskModel> tasks,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildTaskList(tasks)),
      ],
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks yet',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(
            task: task,
            isMagicFixUser: _isMagicFixUser,
            onComplete: task.isPending ? () => _completeTask(task.id) : null,
          ),
        );
      },
    );
  }
}
