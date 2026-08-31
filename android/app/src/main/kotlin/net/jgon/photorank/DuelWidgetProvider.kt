package net.jgon.photorank

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** "Today's Duel": two thumbnails rendered by the app; tapping one opens the
 *  app straight onto that duel with the tapped side pre-selected. */
class DuelWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val a = widgetData.getString("duel_a_path", null)
        val b = widgetData.getString("duel_b_path", null)
        val aId = widgetData.getString("duel_a_id", null)
        val bId = widgetData.getString("duel_b_id", null)
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_duel).apply {
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("photorank://duel")),
                )
                if (a != null && b != null && aId != null && bId != null) {
                    setViewVisibility(R.id.widget_empty, View.GONE)
                    setImageViewBitmap(R.id.duel_a, BitmapFactory.decodeFile(a))
                    setImageViewBitmap(R.id.duel_b, BitmapFactory.decodeFile(b))
                    setOnClickPendingIntent(
                        R.id.duel_a,
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("photorank://duel?a=$aId&b=$bId&pick=$aId")),
                    )
                    setOnClickPendingIntent(
                        R.id.duel_b,
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("photorank://duel?a=$aId&b=$bId&pick=$bId")),
                    )
                } else {
                    setViewVisibility(R.id.widget_empty, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
