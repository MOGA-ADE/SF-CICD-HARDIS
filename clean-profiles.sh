#!/bin/bash
# clean-profiles.sh
# Deletes standard and managed package profiles, keeps custom profiles
# Run from the root of your SF-CICD-HARDIS project

PROFILES_DIR="./force-app/main/default/profiles"

# Standard & managed profiles to DELETE
PROFILES_TO_DELETE=(
  "Admin.profile-meta.xml"
  "Analytics Cloud Integration User.profile-meta.xml"
  "Analytics Cloud Security User.profile-meta.xml"
  "Anypoint Integration.profile-meta.xml"
  "B2BMA Integration User.profile-meta.xml"
  "CPQ Integration User.profile-meta.xml"
  "Chatter External User.profile-meta.xml"
  "Chatter Free User.profile-meta.xml"
  "Chatter Moderator User.profile-meta.xml"
  "ContractManager.profile-meta.xml"
  "Einstein Agent User.profile-meta.xml"
  "External Apps Login User.profile-meta.xml"
  "Guest License User.profile-meta.xml"
  "Identity User.profile-meta.xml"
  "Minimum Access - API Only Integrations.profile-meta.xml"
  "Minimum Access - Salesforce.profile-meta.xml"
  "Partner Community User.profile-meta.xml"
  "Read Only.profile-meta.xml"
  "Sales Insights Integration User.profile-meta.xml"
  "Salesforce API Only System Integrations.profile-meta.xml"
  "SalesforceIQ Integration User.profile-meta.xml"
  "SolutionManager.profile-meta.xml"
  "Standard.profile-meta.xml"
)

echo "🧹 Cleaning standard/managed profiles from $PROFILES_DIR..."
DELETED=0
NOT_FOUND=0

for PROFILE in "${PROFILES_TO_DELETE[@]}"; do
  FILE="$PROFILES_DIR/$PROFILE"
  if [ -f "$FILE" ]; then
    rm "$FILE"
    echo "  ❌ Deleted: $PROFILE"
    ((DELETED++))
  else
    ((NOT_FOUND++))
  fi
done

echo ""
echo "✅ Done!"
echo "   Deleted:   $DELETED profiles"
echo "   Not found: $NOT_FOUND profiles (already removed)"
echo ""
echo "📋 Remaining profiles (custom - KEPT):"
ls "$PROFILES_DIR/"