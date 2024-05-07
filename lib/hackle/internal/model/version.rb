# frozen_string_literal: true

module Hackle
  class Version
    include Comparable

    # @!attribute [r] core_version
    #   @return [CoreVersion]
    # @!attribute [r] prerelease
    #   @return [MetadataVersion]
    # @!attribute [r] build
    #   @return [MetadataVersion]
    attr_reader :core_version, :prerelease, :build

    # @param major [Integer]
    # @param minor [Integer]
    # @param patch [Integer]
    # @param prerelease [MetadataVersion]
    # @param build [MetadataVersion]

    def initialize(core_version:, prerelease:, build:)
      @core_version = core_version
      @prerelease = prerelease
      @build = build
    end

    VERSION_REGEX = /^(0|[1-9]\d*)(?:\.(0|[1-9]\d*))?(?:\.(0|[1-9]\d*))?(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+(\S+))?$/.freeze

    # @param version [Object]
    # @return [Version, nil]
    def self.parse_or_nil(value)
      return nil unless value.is_a?(String)

      match = VERSION_REGEX.match(value)
      return nil unless match

      core_version = CoreVersion.new(major: match[1].to_i, minor: (match[2] || 0).to_i, patch: (match[3] || 0).to_i)
      prerelease = MetadataVersion.parse(match[4])
      build = MetadataVersion.parse(match[5])
      new(core_version: core_version, prerelease: prerelease, build: build)
    end

    def <=>(other)
      core_comparison = core_version <=> other.core_version
      return core_comparison unless core_comparison.zero?

      prerelease <=> other.prerelease
    end

    def ==(other)
      other.is_a?(Version) && (self <=> other).zero?
    end

    def to_s
      str = core_version.to_s
      str += "-#{prerelease}" unless prerelease.empty?
      str += "+#{build}" unless build.empty?
      str
    end
  end

  class CoreVersion
    include Comparable

    # @!attribute [r] major
    #   @return [Integer]
    # @!attribute [r] minor
    #   @return [Integer]
    # @!attribute [r] patch
    #   @return [Integer]
    attr_reader :major, :minor, :patch

    # @param major [Integer]
    # @param minor [Integer]
    # @param patch [Integer]
    def initialize(major:, minor:, patch:)
      @major = major
      @minor = minor
      @patch = patch
    end

    def <=>(other)
      return nil unless other.is_a?(CoreVersion)

      [major, minor, patch] <=> [other.major, other.minor, other.patch]
    end

    def ==(other)
      other.is_a?(CoreVersion) && (major == other.major && minor == other.minor && patch == other.patch)
    end

    def to_s
      "#{major}.#{minor}.#{patch}"
    end
  end

  class MetadataVersion
    include Comparable

    # @!attribute [r] identifiers
    #   @return [Array<String>]
    attr_reader :identifiers

    def initialize(identifiers)
      @identifiers = identifiers
    end

    def self.parse(value)
      return new([]) unless value

      new(value.split('.'))
    end

    def ==(other)
      other.is_a?(MetadataVersion) && identifiers == other.identifiers
    end

    def <=>(other)
      return 0 if empty? && other.empty?
      return -1 if empty?
      return 1 if other.empty?

      compare_identifiers(other)
    end

    def compare_identifiers(other)
      min_length = [identifiers.length, other.identifiers.length].min
      min_length.times do |i|
        result = compare_single_identifier(identifiers[i], other.identifiers[i])
        return result if result != 0
      end
      identifiers.length <=> other.identifiers.length
    end

    def compare_single_identifier(id1, id2)
      num1 = id1.to_i
      num2 = id2.to_i
      if id1.to_i.to_s == id1 && id2.to_i.to_s == id2
        num1 <=> num2
      else
        id1 <=> id2
      end
    end

    def to_s
      identifiers.join('.')
    end

    def empty?
      identifiers.empty?
    end
  end
end
