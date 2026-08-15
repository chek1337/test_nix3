{ ... }:
{
  flake.modules.nixos.remote-access-moonlight =
    {
      lib,
      config,
      pkgs-stable,
      ...
    }:
    lib.mkIf config.settings.enableMoonlightClient {
      # Пин moonlight-qt на stable: в unstable ffmpeg обновился до 9.0, где из
      # AVVulkanDeviceContext убрали queue_family_*_index / nb_*_queues, а
      # moonlight 6.1.0 всё ещё пишет в эти поля (plvk.cpp) и не компилируется.
      # Вернуть на pkgs.moonlight-qt, когда апстрим починит Vulkan-рендерер.
      environment.systemPackages = [ pkgs-stable.moonlight-qt ];
    };
}
