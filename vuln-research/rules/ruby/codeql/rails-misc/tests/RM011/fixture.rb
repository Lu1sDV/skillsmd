module Ci
  class Build
    # BAD: cache protection tier is decided by whether the ref is a protected
    # branch (`pipeline.protected_ref?`), not by the user's actual role.
    # A developer running a job on a protected branch receives the
    # maintainer-tier cache, enabling cross-privilege cache poisoning.
    def cache
      cache = Array.wrap(options[:cache])

      return cache unless project.ci_separated_caches

      cache.map do |entry|
        type_suffix = !entry[:unprotect] && pipeline.protected_ref? ? 'protected' : 'non_protected'

        entry.merge(key: "#{entry[:key]}-#{type_suffix}")
      end
    end
  end
end

module Ci
  class BuildSafe
    # GOOD: cache protection tier is determined by the user's actual role via
    # `project.team.max_member_access(user.id) >= MAINTAINER`, not by the
    # branch protection flag.
    def uses_protected_cache?
      return false unless user
      return false unless project.ci_separated_caches

      project.team.max_member_access(user.id) >= Gitlab::Access::MAINTAINER
    end

    def cache
      cache = Array.wrap(options[:cache])
      apply_cache_protection_suffix(cache)
    end

    private

    def apply_cache_protection_suffix(cache)
      return cache unless project.ci_separated_caches

      cache.map do |entry|
        suffix = entry[:unprotect] || !uses_protected_cache? ? 'non_protected' : 'protected'
        entry.merge(key: "#{entry[:key]}-#{suffix}")
      end
    end
  end
end
