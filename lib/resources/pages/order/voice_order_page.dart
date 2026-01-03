import 'dart:math' as math;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:flutter_app/app/networking/voice_order_api_service.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/app/utils/socket_manager.dart';
import 'package:flutter_app/app/utils/speech_service.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'dart:async';

class SpeechServiceManager {
  static final SpeechServiceManager _instance =
      SpeechServiceManager._internal();
  factory SpeechServiceManager() => _instance;
  SpeechServiceManager._internal();

  SpeechService? _speechService;
  bool _isInitialized = false;
  Future<SpeechService?> getSpeechService() async {
    if (_speechService == null || !_isInitialized) {
      _speechService = SpeechService();
      _isInitialized = await _speechService!.initialize();

      if (!_isInitialized) {
        _speechService = null;
        return null;
      }
    }
    return _speechService;
  }

  void pauseService() {
    if (_speechService?.isListening == true) {
      _speechService!.stopListening();
    }
  }

  Future<void> dispose() async {
    if (_speechService != null) {
      await _speechService!.dispose();
      _speechService = null;
      _isInitialized = false;
    }
  }
}

class VoiceOrderPage extends NyStatefulWidget {
  final Controller controller = Controller();
  static const path = '/voice-order';

  VoiceOrderPage({Key? key}) : super(key: key);

  @override
  NyState<VoiceOrderPage> createState() => _VoiceOrderPageState();
}

class _VoiceOrderPageState extends NyState<VoiceOrderPage>
    with TickerProviderStateMixin {
  final SpeechServiceManager _speechManager = SpeechServiceManager();
  SpeechService? _speechService;
  final ScrollController _scrollController = ScrollController();
  bool get isTable => widget.data()?['is_table'] ?? false;
  List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isLoadingResponse = false;
  String _currentTranscript = '';

  late AnimationController _waveAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  StreamSubscription<String>? _transcriptSubscription;
  StreamSubscription<bool>? _listeningSubscription;

  bool _isDisposed = false;
  bool _showActionButtons = false;
  Timer? _showButtonsTimer;
  bool _showErrorMessage = false;
  String _errorMessage = '';
  String _welcomeText =
      "Xin chào! Trợ lý Aibat sẵn sàng ghi nhận đơn hàng của bạn bằng giọng nói. Hãy nói tên sản phẩm, số lượng hoặc yêu cầu cần thiết.";
  String _displayedWelcomeText = '';
  Timer? _welcomeTimer;
  StreamSubscription? _socketSubscription;
  int messageId = 0;

  @override
  init() async {
    super.init();
    await _socketSubscription?.cancel();
    _socketSubscription = SocketManager().userEventStream.listen((data) {
      if (data['type'] == 'order-created') {
        log('Socket data received: $data');
        handleSocketData(data);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _startWelcomeTypewriter();

    _waveAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _initializeSpeech();
  }

  void _resetAllStates() {
    setState(() {
      _currentTranscript = '';
      _showActionButtons = false;
      _isListening = false;
      _showErrorMessage = false;
      _errorMessage = '';
    });
    _resetShowButtonsTimer();
    _stopAnimations();
  }

  void _startWelcomeTypewriter() {
    _displayedWelcomeText = '';
    _welcomeTimer?.cancel();
    int i = 0;
    _welcomeTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (i < _welcomeText.length) {
        setState(() {
          _displayedWelcomeText += _welcomeText[i];
        });
        i++;
      } else {
        timer.cancel();
      }
    });
  }

  void handleSocketData(dynamic data) {
    if (data == null) return;

    final userId = data['user_id'];
    if (userId == null || userId != Auth.user<User>()?.id) {
      return;
    }

    final messId = data['mess_id'];
    if (messId == null) return;

    final messageIndex = _messages.indexWhere((msg) => msg.id == messId);
    if (messageIndex == -1) return;

    setState(() {
      final orderId = data['id'];

      if (orderId == null) {
        final errorMessage = data['error']?.toString() ?? 'Tạo đơn thất bại';
        _messages[messageIndex].text = errorMessage;
        _messages[messageIndex].isError = true;
        _messages[messageIndex].isLoading = false;
      } else {
        final orderCode = data['code']?.toString() ?? '';
        final successMessage = orderCode.isNotEmpty
            ? 'Đơn hàng $orderCode đã được tạo thành công!'
            : 'Đơn hàng đã được tạo thành công!';

        _messages[messageIndex].text = successMessage;
        _messages[messageIndex].isError = false;
        _messages[messageIndex].isLoading = false;
        _messages[messageIndex].orderId = orderId;
      }
    });
  }

  void _initializeSpeech() async {
    if (_isDisposed) return;

    _speechService = await _speechManager.getSpeechService();

    if (_speechService == null) {
      if (!_isDisposed && mounted) {
        CustomToast.showToastError(context,
            description: 'Không thể khởi tạo mic');
      }
      return;
    }

    _listenToSpeechStreams();
    Future.delayed(Duration(milliseconds: 300), () {
      if (!_isDisposed && mounted && !_isListening) {
        _startListening();
      }
    });
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      id: messageId++,
      text:
          'Xin chào! Nói tên sản phẩm, số lượng hoặc yêu cầu của bạn để tạo đơn hàng.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _listenToSpeechStreams() {
    if (_isDisposed || _speechService == null) return;

    _transcriptSubscription?.cancel();
    _listeningSubscription?.cancel();

    _transcriptSubscription = _speechService!.transcriptStream.listen(
      (transcript) {
        if (!_isDisposed && mounted) {
          setState(() {
            _currentTranscript = transcript;
            _showErrorMessage = false;
          });

          if (transcript.isNotEmpty) {
            _resetShowButtonsTimer();
            _startShowButtonsTimer();
          }
        }
      },
    );

    _listeningSubscription = _speechService!.listeningStream.listen(
      (isListening) {
        if (!_isDisposed && mounted) {
          setState(() {
            if (isListening != false) {
              _isListening = isListening;
            }
          });

          if (isListening) {
            _startAnimations();
            if (_showErrorMessage) {
              setState(() {
                _showErrorMessage = false;
                _errorMessage = '';
              });
            }
          } else {
            _stopAnimations();
            if (_currentTranscript.isNotEmpty && !_showErrorMessage) {
              setState(() {
                _showActionButtons = true;
                _isListening = false;
              });
            }
          }
        }
      },
    );

    _speechService!.errorStream.listen(
      (error) {
        if (!_isDisposed && mounted) {
          setState(() {
            _isListening = false;
          });
          _stopAnimations();
          _handleNoMatchError();
        }
      },
    );
  }

  void _handleNoMatchError() {
    if (_isDisposed || !mounted) return;

    setState(() {
      _showErrorMessage = true;
      _errorMessage = 'Không nhận diện được giọng nói của bạn, hãy nói lại';
      _showActionButtons = false;
      _currentTranscript = '';
      _isListening = false;
    });

    Timer(Duration(milliseconds: 2000), () {
      if (!_isDisposed && mounted) {
        setState(() {
          _showErrorMessage = false;
          _errorMessage = '';
        });
      }
    });
  }

  void _startShowButtonsTimer() {
    _showButtonsTimer = Timer(Duration(seconds: 3), () {
      if (!_isDisposed && mounted && _currentTranscript.isNotEmpty) {
        setState(() {
          _showActionButtons = true;
        });
      }
    });
  }

  void _resetShowButtonsTimer() {
    _showButtonsTimer?.cancel();
    _showButtonsTimer = null;
  }

  void _sendMessage(String text) async {
    if (_isDisposed || text.trim().isEmpty) return;

    final currentMessageId = messageId;

    // Cancel tất cả timer và reset state TRƯỚC KHI setState
    _resetShowButtonsTimer();
    _stopAnimations();
    _speechService?.stopListening();

    // Clear tất cả transcript streams để tránh conflict
    _transcriptSubscription?.cancel();
    _listeningSubscription?.cancel();

    setState(() {
      _currentTranscript = '';
      _showActionButtons = false;
      _isListening = false;
      _showErrorMessage = false;
      _errorMessage = '';

      _messages.add(ChatMessage(
        id: currentMessageId,
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        isVoice: true,
        isLoading: false,
      ));

      _messages.add(ChatMessage(
        id: currentMessageId + 1,
        text: 'Đang suy nghĩ...',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });

    messageId += 2;
    _scrollToBottom();

    var payload = {"text": text, "mess_id": currentMessageId + 1};

    try {
      isTable
          ? await api<VoiceOrderApiService>(
              (request) => request.createVoiceOrderService(payload),
            )
          : await api<VoiceOrderApiService>(
              (request) => request.createVoiceOrder(payload),
            );
    } catch (e) {
      setState(() {
        final messageIndex =
            _messages.indexWhere((msg) => msg.id == currentMessageId + 1);
        if (messageIndex != -1) {
          _messages[messageIndex].text = getResponseError(e);
          _messages[messageIndex].isError = true;
          _messages[messageIndex].isLoading = false;
        }
      });
    }

    // Delay rồi mới khởi tạo lại speech streams và start listening
    Future.delayed(Duration(milliseconds: 1000), () {
      if (!_isDisposed && mounted) {
        _listenToSpeechStreams(); // Khởi tạo lại streams
        _startListening();
      }
    });
  }

  void _stopListening() async {
    if (_isDisposed || _speechService == null) return;
    await _speechService!.stopListening();
    _isListening = false;
    _resetShowButtonsTimer();
    setState(() {});
  }

  Future<void> _startListening() async {
    if (_isDisposed || _speechService == null || _isLoadingResponse) return;

    if (mounted) {
      setState(() {
        _showErrorMessage = false;
        _errorMessage = '';
        _showActionButtons = false;
        _currentTranscript = '';
        _isListening = true;
      });
    }

    final success = await _speechService!.startListening();
    if (success && !_isDisposed && mounted) {}
  }

  void _retryListening() {
    _resetAllStates();
    _startListening();
  }

  void _startAnimations() {
    if (_isDisposed) return;
    if (!_waveAnimationController.isAnimating) {
      _waveAnimationController.repeat();
    }
    if (!_pulseAnimationController.isAnimating) {
      _pulseAnimationController.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    if (_isDisposed) return;
    _waveAnimationController.stop();
    _pulseAnimationController.stop();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    _showButtonsTimer?.cancel();
    _transcriptSubscription?.cancel();
    _listeningSubscription?.cancel();
    _waveAnimationController.dispose();
    _pulseAnimationController.dispose();
    _scrollController.dispose();
    _speechManager.pauseService();
    _welcomeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.mic,
                color: Color(0xFFE91E63),
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Tạo đơn tự động",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _isListening ? "Đang nghe..." : "Sẵn sàng nghe",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _isListening ? Color(0xFFE91E63) : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                _showHelpDialog();
              },
              icon: Icon(Icons.help_outline, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: _messages.length + (_isLoadingResponse ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoadingResponse) {
                      return _buildLoadingMessage();
                    }
                    return _buildMessage(_messages[index], index);
                  },
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: _buildVoiceInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: FadeInImage(
                  placeholder: AssetImage(getImageAsset('placeholder.png')),
                  image: AssetImage(getImageAsset('logo.png')),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Align(
              alignment:
                  message.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: IntrinsicWidth(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? ThemeColor.get(context).primaryAccent
                          : (message.isError
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          index == 0 ? _displayedWelcomeText : message.text,
                          style: TextStyle(
                            color:
                                message.isUser ? Colors.white : Colors.black87,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 10,
                                color: message.isUser
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                            // if (message.orderId != null)
                            // InkWell(
                            //     onTap: () {
                            //       routeTo(DetailOrderPage.path,
                            //           data: {'id': message.orderId});
                            //     },
                            //     child: Text(
                            //       'Xem đơn',
                            //       style: TextStyle(
                            //           fontSize: 11,
                            //           color: ThemeColor.get(context)
                            //               .primaryAccent),
                            //     )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue[100],
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đang xử lý...',
                    style: TextStyle(color: Colors.black87, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[50]!,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: Colors.blue[700],
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Hướng dẫn sử dụng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHelpItem(
                        icon: Icons.mic_rounded,
                        title: 'Bắt đầu nói',
                        description: 'Nhấn nút micro để bắt đầu ghi âm',
                      ),
                      SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.record_voice_over_rounded,
                        title: 'Nói yêu cầu',
                        description:
                            'Nói rõ ràng tên món ăn và số lượng\nVí dụ: "Tôi muốn 2 phở bò và 1 chả cá"',
                      ),
                      SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.timer_rounded,
                        title: 'Chờ xử lý',
                        description: 'Im lặng 3 giây để hệ thống xử lý',
                      ),
                      SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.check_circle_rounded,
                        title: 'Xác nhận',
                        description:
                            'Chọn "Gửi" để tạo đơn hoặc "Nói lại" để ghi âm lại',
                      ),
                      if (isTable) ...[
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Lưu ý: Cần nói rõ tên bàn và khu vực.\nVí dụ: "Bàn 5 tầng 1, 2 phở bò"',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Đã hiểu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue[700],
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (_showErrorMessage) return Colors.red[600]!;
    if (_isListening) return Color(0xFFE91E63);
    if (_isLoadingResponse) return Colors.orange[600]!;
    if (_showActionButtons) return Colors.green[600]!;
    return Colors.grey[600]!;
  }

  String _getStatusText() {
    if (_showErrorMessage) return '';
    if (_isListening) return 'Đang nghe...';
    if (_isLoadingResponse) return 'Đang xử lý...';
    if (_showActionButtons) return 'Chờ xác nhận';
    return 'Sẵn sàng';
  }

  String _getHelpText() {
    if (_isLoadingResponse) return 'Đang xử lý yêu cầu của bạn...';
    if (_showActionButtons)
      return 'Chọn "Nói lại" để ghi âm lại hoặc "Gửi" để tạo đơn';
    if (_isListening) return 'Nhấn để dừng nghe';
    return 'Nhấn micro để bắt đầu nói yêu cầu';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isListening && _currentTranscript.isEmpty)
          AnimatedBuilder(
            animation: _waveAnimationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(200, 80),
                painter: SoundBarsAnimationPainter(
                  animationValue: _waveAnimationController.value,
                  isListening: _isListening,
                ),
              );
            },
          ),
        if (_currentTranscript.isEmpty)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: _isLoadingResponse
                      ? null
                      : (_isListening ? _stopListening : _startListening),
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [Color(0xFFE91E63), Color(0xFFAD1457)]
                            : _isLoadingResponse
                                ? [Colors.grey[400]!, Colors.grey[500]!]
                                : [Colors.blue[500]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? Color(0xFFE91E63)
                                  : _isLoadingResponse
                                      ? Colors.grey
                                      : Colors.blue)
                              .withOpacity(0.4),
                          blurRadius: _isListening ? 15 : 8,
                          spreadRadius: _isListening ? 3 : 1,
                        ),
                      ],
                    ),
                    child: _isLoadingResponse
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVoiceInputArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.grey[50]!.withOpacity(0.95),
            Colors.blue[50]!.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, -2),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.28,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_showErrorMessage)
                  Container(
                    margin: EdgeInsets.only(bottom: 6),
                    padding:
                        EdgeInsets.only(top: 6, bottom: 6, left: 12, right: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.18),
                        width: 0.7,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 8),
                if (_currentTranscript.isNotEmpty && !_showErrorMessage)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[50]!,
                          Colors.blue[25] ?? Colors.blue[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!, width: 0.7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.07),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: Colors.blue[300],
                          size: 16,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _currentTranscript,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!_showActionButtons && _isListening) ...[
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Nói tiếp hoặc chờ 3 giây...',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (_showErrorMessage)
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red[50]!,
                          Colors.red[25] ?? Colors.red[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!, width: 0.7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.07),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[800],
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_showErrorMessage) ...[
                  if (_showActionButtons && _currentTranscript.isNotEmpty) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.refresh_rounded,
                              label: 'Nói lại',
                              color: Colors.orange,
                              onTap: _retryListening,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.send_rounded,
                              label: 'Gửi',
                              color: Colors.green,
                              onTap: () => _sendMessage(_currentTranscript),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: _buildVoiceButton(),
                    ),
                  ],
                ],
                if (!_showErrorMessage)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getHelpText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final int id;
  String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isVoice;
  bool isError;
  bool isLoading;
  int? orderId;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isVoice = false,
    this.isError = false,
    this.isLoading = false,
    this.orderId,
  });
}

class SoundBarsAnimationPainter extends CustomPainter {
  final double animationValue;
  final bool isListening;

  SoundBarsAnimationPainter(
      {required this.animationValue, required this.isListening});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double maxBarHeight = size.height * 0.4;
    final int barCount = 40;
    final double barWidth = 3.0;
    final double spacing = 2.0;
    final double totalWidth = barCount * (barWidth + spacing);
    final double startX = centerX - totalWidth / 2;

    for (int i = 0; i < barCount; i++) {
      final double frequency1 = (animationValue * 2 + i * 0.1) % 1.0;
      final double frequency2 = (animationValue * 3 + i * 0.15) % 1.0;
      final double frequency3 = (animationValue * 1.5 + i * 0.08) % 1.0;

      final double wave1 = math.sin(frequency1 * 2 * math.pi);
      final double wave2 = math.sin(frequency2 * 2 * math.pi) * 0.5;
      final double wave3 = math.sin(frequency3 * 2 * math.pi) * 0.3;
      final double combinedWave = (wave1 + wave2 + wave3) / 1.8;

      final double barHeight = (combinedWave.abs() * 0.8 + 0.2) * maxBarHeight;
      final double barX = startX + i * (barWidth + spacing);

      final double normalizedHeight = barHeight / maxBarHeight;
      final double centerDistance = (i - barCount / 2).abs() / (barCount / 2);

      Color barColor;
      if (normalizedHeight > 0.7) {
        barColor =
            Color.lerp(Color(0xFFE91E63), Color(0xFF9C27B0), centerDistance)!
                .withOpacity(0.8);
      } else if (normalizedHeight > 0.4) {
        barColor = Color.lerp(Color(0xFFE91E63).withOpacity(0.6),
            Color(0xFF9C27B0).withOpacity(0.6), centerDistance)!;
      } else {
        barColor = Color.lerp(Color(0xFFE91E63).withOpacity(0.3),
            Color(0xFF9C27B0).withOpacity(0.3), centerDistance)!;
      }

      paint.color = barColor;

      final Rect barRect = Rect.fromLTWH(
        barX,
        centerY - barHeight / 2,
        barWidth,
        barHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(barWidth / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
