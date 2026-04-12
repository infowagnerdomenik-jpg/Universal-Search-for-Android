//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <design_engine/design_engine_plugin.h>
#include <dynamic_color/dynamic_color_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) design_engine_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesignEnginePlugin");
  design_engine_plugin_register_with_registrar(design_engine_registrar);
  g_autoptr(FlPluginRegistrar) dynamic_color_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DynamicColorPlugin");
  dynamic_color_plugin_register_with_registrar(dynamic_color_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
}
