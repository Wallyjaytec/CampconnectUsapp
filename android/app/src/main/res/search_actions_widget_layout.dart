<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="12dp"
    android:background="@drawable/widget_background">

    <!-- Header -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical"
        android:layout_marginBottom="8dp">
        <ImageView
            android:id="@+id/widget_header_icon"
            android:layout_width="20dp"
            android:layout_height="20dp"
            android:src="@mipmap/ic_launcher"
            android:layout_marginEnd="6dp" />
        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="CampConnectUs"
            android:textSize="13sp"
            android:textColor="#FF8C00"
            android:textStyle="bold" />
        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Shop on CCU"
            android:textSize="9sp"
            android:textColor="#999999" />
    </LinearLayout>

    <!-- Search bar -->
    <LinearLayout
        android:id="@+id/widget_search_bar"
        android:layout_width="match_parent"
        android:layout_height="38dp"
        android:background="@drawable/widget_search_bg"
        android:gravity="center_vertical"
        android:paddingStart="10dp"
        android:paddingEnd="10dp"
        android:orientation="horizontal"
        android:clickable="true"
        android:focusable="true">
        <ImageView
            android:layout_width="18dp"
            android:layout_height="18dp"
            android:src="@android:drawable/ic_menu_search"
            android:tint="#FF8C00" />
        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:layout_marginStart="8dp"
            android:text="Search Products..."
            android:textColor="#999999"
            android:textSize="13sp" />
        <ImageView
            android:layout_width="18dp"
            android:layout_height="18dp"
            android:src="@android:drawable/ic_menu_camera"
            android:tint="#FF8C00" />
    </LinearLayout>

    <!-- Quick action buttons -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:orientation="horizontal"
        android:gravity="center">

        <LinearLayout
            android:id="@+id/widget_account"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center"
            android:clickable="true"
            android:focusable="true"
            android:padding="4dp">
            <ImageView
                android:layout_width="22dp"
                android:layout_height="22dp"
                android:src="@android:drawable/ic_menu_edit"
                android:tint="#FF8C00" />
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Account"
                android:textSize="10sp"
                android:textColor="#333333" />
        </LinearLayout>

        <LinearLayout
            android:id="@+id/widget_cart"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center"
            android:clickable="true"
            android:focusable="true"
            android:padding="4dp">
            <ImageView
                android:layout_width="22dp"
                android:layout_height="22dp"
                android:src="@android:drawable/ic_menu_slideshow"
                android:tint="#FF8C00" />
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Cart"
                android:textSize="10sp"
                android:textColor="#333333" />
        </LinearLayout>

        <LinearLayout
            android:id="@+id/widget_orders"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center"
            android:clickable="true"
            android:focusable="true"
            android:padding="4dp">
            <ImageView
                android:layout_width="22dp"
                android:layout_height="22dp"
                android:src="@android:drawable/ic_menu_view"
                android:tint="#FF8C00" />
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Orders"
                android:textSize="10sp"
                android:textColor="#333333" />
        </LinearLayout>

        <LinearLayout
            android:id="@+id/widget_notifications"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center"
            android:clickable="true"
            android:focusable="true"
            android:padding="4dp">
            <ImageView
                android:layout_width="22dp"
                android:layout_height="22dp"
                android:src="@android:drawable/ic_menu_info_details"
                android:tint="#FF8C00" />
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Notif"
                android:textSize="10sp"
                android:textColor="#333333" />
        </LinearLayout>
    </LinearLayout>

</LinearLayout>
