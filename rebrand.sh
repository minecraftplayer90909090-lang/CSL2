#!/usr/bin/env bash
# Masterix Plus rebrand. Repo ke root se chalao: bash rebrand.sh
# Idempotent hai: kitni bhi baar chalao, nuksan nahi. Upstream merge ke baad dobara chalao.
set -u

NAME="Masterix Plus"          # dikhne wala app naam
NAME_UP="MASTERIX PLUS"
VERSION_TEXT="v2.7"           # screen par dikhne wala version
VERSION_NAME="2.7"            # build.gradle ka versionName
OWNER="AbhayTheMaster"        # credit me tumhara naam
OWNER_UP="ABHAYTHEMASTER"
OLDID="com.craftstudio.cslauncher"
NEWID="com.abhaythemaster.masterixplus"
UPDATE_REPO="minecraftplayer90909090-lang/CSL2"   # update checker ab yahan dekhega

[ -d app_cs ] || { echo "ERROR: app_cs folder nahi mila. Repo ke root me chalao."; exit 1; }

RES=app_cs/src/main/res
ASSETS=app_cs/src/main/assets
JAVA=app_cs/src/main/java
GRADLE=app_cs/build.gradle
MANIFEST=app_cs/src/main/AndroidManifest.xml
CHECKER=$JAVA/com/craftstudio/cslauncher/update/UpdateChecker.java
APIH=$JAVA/com/craftstudio/cslauncher/modding/modpacks/api/ApiHandler.java
NBSP=$(printf '\xc2\xa0')     # "CS Launcher" me normal space ki jagah NBSP: dobara chalane par ye line nahi badlegi

echo "[1/5] Strings, assets (sab languages)..."
find "$RES" "$ASSETS" -type f \( -name '*.xml' -o -name '*.txt' -o -name '*.json' \) -print0 |
xargs -0 sed -i -E \
  -e "s/CS Launcher Plus 1\.4/$NAME $VERSION_TEXT/g" \
  -e "s/CS Launcher Plus/$NAME/g" \
  -e "s/CS Launcher/$NAME/g" \
  -e "s/CS LAUNCHER PLUS/$NAME_UP/g" \
  -e "s/CS LAUNCHER/$NAME_UP/g" \
  -e "s/(name=\"brand_version\">)[^<]*(<)/\1$VERSION_TEXT\2/" \
  -e "s/(name=\"app_short_name\"[^>]*>)[^<]*(<)/\1$NAME\2/" \
  -e "/name=\"(brand_team_name|brand_team_tag)\"/s/CRAFT STUDIO/$OWNER/g" \
  -e "/name=\"brand_by_studio\"/s/CRAFT STUDIO/$OWNER_UP/g" \
  -e "/name=\"home_about_text\"/s/by CRAFT STUDIO/by $OWNER/g"

# About footer (sirf default English): tumhara naam + original credit
sed -i "s/Made with ❤ by CRAFT STUDIO and the open source community/Made with ❤ by $OWNER. Based on CS${NBSP}Launcher Plus by CRAFT STUDIO and the open source community/" "$RES/values/strings.xml"

echo "[2/5] Java ke text literals (comments nahi chhute)..."
find "$JAVA" -type f -name '*.java' ! -name 'UpdateManager.java' -print0 |
xargs -0 sed -i -E \
  -e "/^[[:space:]]*(\*|\/\/|\/\*)/!{s/CS Launcher Plus/$NAME/g;s/CS Launcher/$NAME/g}"
[ -f "$APIH" ] && sed -i "s#CSLauncherPlus/1\.4 (by Craft Studio)#MasterixPlus/$VERSION_NAME (by $OWNER)#" "$APIH"

echo "[3/5] Package id..."
sed -i -E \
  -e "s/(applicationId \")$OLDID(\")/\1$NEWID\2/" \
  -e "/resValue 'string', '(application_package|storageProviderAuthorities)'/s/$OLDID/$NEWID/" \
  -e "s/(versionName \")[^\"]*(\")/\1$VERSION_NAME\2/" \
  "$GRADLE"
sed -i "/<package android:name=\"$OLDID/s/$OLDID/$NEWID/" "$MANIFEST"

echo "[4/5] Update checker -> tumhari repo..."
[ -f "$CHECKER" ] && sed -i "s#\"JoooaoooDVD/CSL2\"#\"$UPDATE_REPO\"#" "$CHECKER"

echo "[5/5] Report"
echo "  applicationId  : $(grep -m1 'applicationId "' $GRADLE | xargs)"
echo "  versionName    : $(grep -m1 'versionName "' $GRADLE | xargs)"
echo "  update repo    : $(grep -m1 'String REPO' $CHECKER | xargs)"
echo "  app_short_name : $(grep -m1 'name="app_short_name"' $RES/values/strings.xml | xargs)"
echo "  bacha 'CS Launcher' (res+assets): $(grep -rIF 'CS Launcher' $RES $ASSETS | wc -l)"
echo "  bacha 'CS Launcher' (java literals): $(grep -rInF 'CS Launcher' $JAVA | grep -vE '^[^:]*:[0-9]*:[[:space:]]*(\*|//|/\*)' | wc -l)"
git diff --stat 2>/dev/null | tail -1
echo "Ho gaya. Ab: git diff --stat dekho, phir commit + push."
