import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/order.dart' as model; // Alias to avoid conflict with standard Order classes

class ClientOrdersScreen extends StatelessWidget {
  const ClientOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Identify the currently logged-in user
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = const Color(0xFFEE4D2D);

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // ADDED: Match new app background
        appBar: AppBar(
          title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey.shade200, height: 1),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container( // ADDED: Soft circle background for icon
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
                child: Icon(Icons.lock_outline, size: 60, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),
              const Text("Login Required", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text("Please login to view your order history.", style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // ADDED: Cooler light grey
      appBar: AppBar(
        title: const Text("Order Tracker", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.2)), // ADDED: Bolder typography
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize( // ADDED: Hairline border instead of shadow
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      // 2. Real-time stream listening for orders belonging to this specific User ID
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor)); // ADDED: Branded loading color
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading orders", style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container( // ADDED: Premium empty state circle
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                    child: Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 24),
                  Text("No active orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)), // ADDED: Bolder text
                  const SizedBox(height: 8),
                  Text("When you place an order,\nits status will appear here.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, height: 1.4)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // ADDED: Better padding
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final order = model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              
              return _buildOrderCard(context, order, primaryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, model.Order order, Color primaryColor) {
    return Container( // ADDED: Replaced standard Card with modern floating Container
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // ADDED: Smooth corners
        border: Border.all(color: Colors.grey.shade200), // ADDED: Subtle edge
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)) // ADDED: Floating shadow
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0), // ADDED: Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reference ID and Formatted Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // ADDED: Align to top
              children: [
                Column( // ADDED: Grouped ID and Date together
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${order.referenceId.split('-').last}", 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87) // ADDED: Heavier font
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt), // ADDED: Included year for clarity
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status, primaryColor), // ADDED: Modern Status Badge
              ],
            ),
            const SizedBox(height: 24), // ADDED: More spacing
            
            // --- THE PIZZA TRACKER ---
            _buildTracker(order.status, primaryColor),
            
            const SizedBox(height: 24),
            
            // Itemized List
            Container( // ADDED: Wrapped items in a designated box
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100)
              ),
              child: Column(
                children: order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6), // ADDED: Spacing between list items
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container( // ADDED: Highlight pill for quantity
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                        child: Text("${item.quantity}x", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)), // ADDED: Bolder product name
                      ),
                      Text("₱${(item.price * item.quantity).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                    ],
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1), // ADDED: Clean separator
            const SizedBox(height: 16),
            
            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                Text(
                  "₱${order.total.toStringAsFixed(2)}", 
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5) // ADDED: Bigger, tighter total
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: DYNAMIC STATUS BADGE ---
  Widget _buildStatusBadge(String status, Color primaryColor) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = "CONFIRMED";
        break;
      case 'shipped':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        label = "SHIPPED";
        break;
      case 'delivered':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = "DELIVERED";
        break;
      case 'cancelled':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = "CANCELLED";
        break;
      case 'pending':
      default:
        bgColor = primaryColor.withOpacity(0.1);
        textColor = primaryColor;
        label = "PENDING";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2))
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  // --- TRACKER UI LOGIC ---
  Widget _buildTracker(String status, Color primaryColor) {
    // 1. Define sequence of statuses
    final steps = ['pending', 'confirmed', 'shipped', 'delivered'];
    
    // 2. Special UI for Cancelled status
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // ADDED: Better padding
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.shade50, 
          borderRadius: BorderRadius.circular(12), // ADDED: Rounder corners
          border: Border.all(color: Colors.red.shade100) // ADDED: Border
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20), // ADDED: Cleaner icon
            const SizedBox(width: 8),
            Text("This order was cancelled", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // 3. Find current index based on database status
    int currentStepIndex = steps.indexOf(status);
    if (currentStepIndex == -1) currentStepIndex = 0; 

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep(Icons.receipt_long, "Placed", 0, currentStepIndex, primaryColor),
        _buildLine(0, currentStepIndex, primaryColor),
        // Step 1: Changed icon to Check Circle and Label to Confirmed
        _buildStep(Icons.check_circle_outline, "Confirmed", 1, currentStepIndex, primaryColor), 
        _buildLine(1, currentStepIndex, primaryColor),
        _buildStep(Icons.local_shipping_outlined, "On Way", 2, currentStepIndex, primaryColor), // ADDED: Better truck icon
        _buildLine(2, currentStepIndex, primaryColor),
        _buildStep(Icons.home_outlined, "Delivered", 3, currentStepIndex, primaryColor), // ADDED: Outline icon for consistency
      ],
    );
  }

  // Helper: Individual Status Step
  Widget _buildStep(IconData icon, String label, int stepIndex, int currentIndex, Color primaryColor) {
    final bool isCompleted = currentIndex >= stepIndex;
    final bool isCurrent = currentIndex == stepIndex;
    
    // ADDED: Logic for distinct colors
    Color circleColor = isCurrent ? primaryColor : (isCompleted ? Colors.green.shade500 : Colors.grey.shade100);
    Color iconColor = isCompleted ? Colors.white : Colors.grey.shade400;
    
    return Column(
      children: [
        AnimatedContainer( // ADDED: Smooth transition if status changes while looking at it
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isCurrent ? 12.0 : 10.0), // ADDED: Current step is slightly larger
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            boxShadow: [
              if (isCurrent) BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2) // ADDED: Glow on active step
            ]
          ),
          child: Icon(
            icon, 
            color: iconColor, 
            size: 20
          ),
        ),
        const SizedBox(height: 8), // ADDED: Pushed text down slightly
        Text(
          label, 
          style: TextStyle(
            fontSize: 11, // ADDED: Slightly larger
            color: isCurrent ? primaryColor : (isCompleted ? Colors.black87 : Colors.grey.shade500), // ADDED: Text color matches state
            fontWeight: isCurrent ? FontWeight.bold : (isCompleted ? FontWeight.w600 : FontWeight.normal)
          )
        ),
      ],
    );
  }

  // Helper: Connecting Line
  Widget _buildLine(int stepIndex, int currentIndex, Color primaryColor) {
    final bool isCompleted = currentIndex > stepIndex; 
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24), // ADDED: Pushed line up to align with circles, not text
        height: 3, // ADDED: Thicker line
        color: isCompleted ? Colors.green.shade400 : Colors.grey.shade200, // ADDED: Softer green
      ),
    );
  }
}