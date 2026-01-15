import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../common/app_colors.dart';
import 'models/dashboard_models.dart';
import 'providers/dashboard_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _isLoadScheduled = false;
  static int _buildCount = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      final dashboard = context.read<DashboardProvider>();
      if (dashboard.hasMoreTickets && !dashboard.loadingMore) {
        dashboard.loadMoreTickets();
      }
    }
  }

  Future<void> _loadData(BuildContext context) async {
    _isLoadScheduled = true;

    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.profile == null) {
      _isLoadScheduled = false;
      return;
    }

    await context.read<DashboardProvider>().loadData(
      token: auth.token!,
      role: auth.profile!.role,
    );

    _isLoadScheduled = false;
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    if (_buildCount % 10 == 0) {}

    return Consumer2<AuthProvider, DashboardProvider>(
      builder: (context, auth, dashboard, _) {
        // Trigger initial load only once
        if (!dashboard.loading &&
            !dashboard.hasLoadedOnce &&
            !_isLoadScheduled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadData(context);
          });
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
          appBar: AppBar(
            elevation: 1,
            backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
            automaticallyImplyLeading: false,
            title: const Text(
              'Pepa Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actionsPadding: EdgeInsets.only(right: 16),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    auth.profile?.displayName ?? 'User',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      auth.profile?.role.name.toUpperCase() ?? 'role',
                      style: TextStyle(
                        color: isDark ? AppColors.primaryColor : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          body: _buildBody(dashboard, context),
        );
      },
    );
  }

  Widget _buildBody(DashboardProvider dashboard, BuildContext context) {
    if (dashboard.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboard.error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                dashboard.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadData(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!dashboard.hasData) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(context),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildStatsCards(dashboard)),
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(
          //       horizontal: 16.0,
          //       vertical: 4,
          //     ),
          //     child: Text(
          //       'Choose Event',
          //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          //     ),
          //   ),
          // ),
          // SliverToBoxAdapter(child: _buildEventFilter(dashboard, context)),
          SliverToBoxAdapter(child: _buildTabSelector(dashboard)),
          _buildTicketsList(dashboard),
          if (dashboard.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (!dashboard.hasMoreTickets && dashboard.filteredTickets.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'All tickets loaded',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- FIX APPLIED HERE ---
  Widget _buildStatsCards(DashboardProvider dashboard) {
    final runningEvent = dashboard.currentRunningEvent;
    final upcomingEvent = dashboard.nextUpcomingEvent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Events',
                  dashboard.dashboardData!.events.length.toString(),
                  Icons.confirmation_number_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Tickets',
                  dashboard.dashboardData!.totalAttendeesTickets.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Show running event card
          if (runningEvent != null)
            _buildCurrentEventCard(dashboard, runningEvent, true),
          // Show upcoming event card (with spacing if running event exists)
          if (upcomingEvent != null) ...[
            if (runningEvent != null) const SizedBox(height: 8),
            _buildCurrentEventCard(dashboard, upcomingEvent, false),
          ],
        ],
      ),
    );
  }
  // --- END FIX ---

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.grey.shade900 : Colors.white,

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEventCard(
    DashboardProvider dashboard,
    EventData event,
    bool isRunning,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isRunning ? Colors.green : Colors.orange;
    final icon = isRunning ? Icons.play_circle_filled : Icons.schedule;
    final label = isRunning ? 'Currently Running' : 'Upcoming Event';

    // Get date time info
    final startDateTime = dashboard.getEventStartDateTime(event);
    final timeInfo = isRunning
        ? dashboard.getTimeRemaining(event)
        : dashboard.getTimeUntilStart(event);

    // Format date and time for display
    String dateTimeText = '';
    if (startDateTime != null) {
      final dateStr =
          '${startDateTime.day}/${startDateTime.month}/${startDateTime.year}';
      final timeStr =
          '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
      dateTimeText = isRunning ? '' : '$dateStr at $timeStr';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dateTimeText.isNotEmpty || timeInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  if (dateTimeText.isNotEmpty) ...[
                    Icon(Icons.calendar_today, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      dateTimeText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                  if (timeInfo.isNotEmpty) ...[
                    if (dateTimeText.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 14,
                        color: color.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      isRunning ? Icons.timer_outlined : Icons.access_time,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeInfo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventFilter(DashboardProvider dashboard, BuildContext context) {
    final events = dashboard.dashboardData?.events ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          menuWidth: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(12),
          isExpanded: true,
          value: dashboard.selectedEventId,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: [
            DropdownMenuItem<String?>(
              child: Row(
                children: [
                  Icon(Icons.event, size: 20, color: AppColors.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'All Events',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ...events.map((event) {
              return DropdownMenuItem<String?>(
                value: event.id,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(event.thumbnail),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            dashboard.setSelectedEventId(value);
          },
        ),
      ),
    );
  }

  Widget _buildTabSelector(DashboardProvider dashboard) {
    final data = dashboard.dashboardData;
    if (data == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'All Tickets',
              0,
              dashboard.filteredAllCount,
              dashboard,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Scanned',
              1,
              dashboard.filteredScannedCount,
              dashboard,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Unscanned',
              2,
              dashboard.filteredUnscannedCount,
              dashboard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    int index,
    int count,
    DashboardProvider dashboard,
  ) {
    final isSelected = dashboard.selectedTab == index;
    final color = isSelected ? AppColors.primaryColor : Colors.grey.shade600;

    return InkWell(
      onTap: () => dashboard.setSelectedTab(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  bottom: BorderSide(color: AppColors.primaryColor, width: 3),
                )
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(DashboardProvider dashboard) {
    final tickets = dashboard.filteredTickets;

    if (tickets.isEmpty) {
      // Different messages based on selected tab
      String message;
      IconData icon;

      switch (dashboard.selectedTab) {
        case 1: // Scanned
          message = 'No scanned tickets';
          icon = Icons.check_circle_outline;
          break;
        case 2: // Unscanned
          message = 'No unscanned tickets';
          icon = Icons.pending_outlined;
          break;
        default: // All
          message = 'No tickets found';
          icon = Icons.inbox_outlined;
      }

      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(icon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              if (message.isNotEmpty) const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ticket = tickets[index];
          return _buildTicketCard(context, ticket);
        }, childCount: tickets.length),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketData ticket) {
    final isScanned = ticket.isScanned;
    final statusColor = isScanned ? Colors.green : Colors.orange;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showTicketDetails(context, ticket),
      child: Card(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isScanned ? Icons.check_circle : Icons.pending,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.scanStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildStatusDropdown(context, ticket),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.eventName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                ticket.ticketName,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    ticket.customerPhone,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'Ticket ID: ${ticket.ticketId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, TicketData ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          value: ticket.scanStatus.toLowerCase(),
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: Colors.grey.shade700,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
          items: const [
            DropdownMenuItem(
              value: 'scanned',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  SizedBox(width: 6),
                  Text('Scanned'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'unscanned',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending, size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Text('Unscanned'),
                ],
              ),
            ),
          ],
          onChanged: (newStatus) {
            if (newStatus != null &&
                newStatus != ticket.scanStatus.toLowerCase()) {
              _updateTicketStatus(context, ticket, newStatus);
            }
          },
        ),
      ),
    );
  }

  Future<void> _updateTicketStatus(
    BuildContext context,
    TicketData ticket,
    String newStatus,
  ) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.profile == null) return;

    final success = await context.read<DashboardProvider>().updateTicketStatus(
      token: auth.token!,
      role: auth.profile!.role,
      bookingId: ticket.bookingId,
      ticketId: ticket.ticketId,
      status: newStatus,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Ticket status updated to ${newStatus.toUpperCase()}'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Failed to update ticket status'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showTicketDetails(BuildContext context, TicketData ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ticket Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Event', ticket.eventName),
            _buildDetailRow('Ticket Type', ticket.ticketName),
            _buildDetailRow('Ticket ID', ticket.ticketId),
            _buildDetailRow('Booking ID', ticket.bookingId),
            _buildDetailRow('Customer Phone', ticket.customerPhone),
            _buildDetailRow(
              'Payment Status',
              ticket.paymentStatus.toUpperCase(),
            ),
            _buildDetailRow(
              'Scan Status',
              ticket.scanStatus.toUpperCase(),
              valueColor: ticket.isScanned ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.grey.shade300
                    : valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
