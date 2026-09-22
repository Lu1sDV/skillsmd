# Fixture for SamlExternUidAccountTakeover
# BAD cases: extern_uid updated without invalidating trusted_extern_uid
# GOOD cases: extern_uid updated AND trusted_extern_uid is invalidated

# --- BAD: API endpoint updates extern_uid without marking it untrusted ---
class VulnerableProviderIdentityApi
  def update_saml_identity
    identity = Identity.find(params[:id])
    # BAD: updates extern_uid but never sets trusted_extern_uid = false
    if identity.update(extern_uid: params[:extern_uid])
      present identity
    end
  end
end

# --- BAD: identity linker uses assign_attributes + save without trust invalidation ---
class VulnerableIdentityLinker
  def update_extern_uid
    # BAD: assign_attributes sets extern_uid but trusted_extern_uid is not touched
    identity.assign_attributes(extern_uid: new_uid)
    identity.save
  end
end

# --- GOOD: API endpoint updates extern_uid AND sets trusted_extern_uid = false ---
class FixedProviderIdentityApi
  def update_saml_identity
    identity = Identity.find(params[:id])
    identity.assign_attributes(extern_uid: params[:extern_uid])
    # GOOD: trust is explicitly invalidated before saving
    identity.trusted_extern_uid = false if provider_type == 'saml' && identity.extern_uid_changed?
    if identity.save
      Notify.saml_extern_uid_changed_email(identity.user, group.name).deliver_later
      present identity
    end
  end
end

# --- GOOD: update call includes trusted_extern_uid: false in the same call ---
class FixedLinker
  def update_extern_uid
    # GOOD: trusted_extern_uid is set to false alongside extern_uid
    identity.update(extern_uid: new_uid, trusted_extern_uid: false)
  end
end
