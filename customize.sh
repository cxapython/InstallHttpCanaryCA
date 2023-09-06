#
# Magisk模块安装脚本
#
# 使用说明:
#
# 1. 将文件放入系统文件夹(删除placeholder文件)
# 2. 在module.prop中填写您的模块信息
# 3. 在此文件中配置和调整
# 4. 如果需要开机执行脚本，请将其添加到post-fs-data.sh或service.sh
# 5. 将其他或修改的系统属性添加到system.prop
#
######################################
#
# 安装框架将导出一些变量和函数。
# 您应该使用这些变量和函数来进行安装。
#
# !请不要使用任何Magisk的内部路径，因为它们不是公共API。
# !请不要在util_functions.sh中使用其他函数，因为它们也不是公共API。
# !不能保证非公共API在版本之间保持兼容性。
#
# 可用变量:
#
# MAGISK_VER (string):当前已安装Magisk的版本的字符串(字符串形式的Magisk版本)
# MAGISK_VER_CODE (int):当前已安装Magisk的版本的代码(整型变量形式的Magisk版本)
# BOOTMODE (bool):如果模块当前安装在Magisk Manager中，则为true。
# MODPATH (path):你的模块应该被安装到的路径
# TMPDIR (path):一个你可以临时存储文件的路径
# ZIPFILE (path):模块的安装包（zip）的路径
# ARCH (string): 设备的体系结构。其值为arm、arm64、x86、x64之一
# IS64BIT (bool):如果$ARCH(上方的ARCH变量)为arm64或x64，则为true。
# API (int):设备的API级别（Android版本）
#
# 可用函数:
#
# ui_print <msg>
#     打印(print)<msg>到控制台
#     避免使用'echo'，因为它不会显示在第三方recovery的控制台中。
#
# abort <msg>
#     打印错误信息<msg>到控制台并终止安装
#     避免使用'exit'，因为它会跳过终止的清理步骤
#
##################################
#
# 如果您需要更多的自定义，并且希望自己做所有事情
# 请在custom.sh中标注SKIPUNZIP=1
# 以跳过提取操作并应用默认权限/上下文上下文步骤。
# 请注意，这样做后，您的custom.sh将负责自行安装所有内容。
SKIPUNZIP=0
# 如果您需要调用Magisk内部的busybox
# 请在custom.sh中标注ASH_STANDALONE=1
ASH_STANDALONE=1

ui_print "正在开始安装证书"

if [[ "$(pm list packages com.guoshi.httpcanary)" == "" ]]; then
    abort "你还没有安装HTTPCanary"
fi

# Create a separate temp directory, to hold the current certificates
# Without this, when we add the mount we can't read the current certs anymore.
mkdir -m 700 /data/local/tmp/cert
# Copy out the existing certificates
cp /system/etc/security/cacerts/* /data/local/tmp/cert/
# Create the in-memory mount on top of the system certs folder
mount -t tmpfs tmpfs /system/etc/security/cacerts
# Copy the existing certs back into the tmpfs mount, so we keep trusting them
mv /data/local/tmp/cert/* /system/etc/security/cacerts/
# Copy our new cert in, so we trust that too
cp /data/local/tmp/87bc3517.0 /system/etc/security/cacerts/
# Update the perms & selinux context labels, so everything is as readable as before
chown root:root /system/etc/security/cacerts/*
chmod 644 /system/etc/security/cacerts/*
chcon u:object_r:system_file:s0 /system/etc/security/cacerts/*
# Delete the temp cert directory & this script itself
rm -r /data/local/tmp/cert
# rm ${injectionScriptPath}
ui_print "System cert successfully injected"
ui_print "证书安装完毕"
ui_print "如果清除数据或重装了HTTPCanary，请再次安装此模块"

######################################
# 安装设置
#
# 如果SKIPUNZIP=1你将可能会需要使用以下代码
# 当然，你也可以自定义安装脚本，需要时请删除#
# 将 $ZIPFILE 提取到 $MODPATH
#  ui_print "- 解压模块文件"
#  unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
# 删除多余文件
# rm -rf \
# $MODPATH/system/placeholder $MODPATH/customize.sh \
# $MODPATH/*.md $MODPATH/.git* $MODPATH/LICENSE 2>/dev/null

#
# 权限设置
#

# 请注意，magisk模块目录中的所有文件/文件夹都有$MODPATH前缀-在所有文件/文件夹中保留此前缀
# 一些例子:
  
# 对于目录(包括文件):
# set_perm_recursive  <目录>                <所有者> <用户组> <目录权限> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  
# set_perm_recursive $MODPATH/system/lib 0 0 0755 0644
# set_perm_recursive $MODPATH/system/vendor/lib/soundfx 0 0 0755 0644

# 对于文件(不包括文件所在目录)
# set_perm  <文件名>                         <所有者> <用户组> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  
# set_perm $MODPATH/system/lib/libart.so 0 0 0644
# set_perm /data/local/tmp/file.txt 0 0 644

# 默认权限请勿删除
set_perm_recursive $MODPATH 0 0 0755 0644

