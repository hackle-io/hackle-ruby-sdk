# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/model/version'

module Hackle
  describe Version do
    # @return [Hackle::Version]
    def v(version_string)
      version = Version.parse_or_nil(version_string)
      raise ArgumentError, 'Invalid version' unless version

      version
    end

    def invalid(s)
      expect(Version.parse_or_nil(s)).to be_nil
    end

    def verify(version_string, major, minor, patch, prerelease, build)
      version = Version.parse_or_nil(version_string)
      expect(version).not_to be_nil

      expected_version = Version.new(
        core_version: CoreVersion.new(major: major, minor: minor, patch: patch),
        prerelease: MetadataVersion.new(prerelease),
        build: MetadataVersion.new(build)
      )

      expect(version).to eq(expected_version)
    end

    it 'when not string type then cannot parse' do
      invalid(nil)
      invalid(42)
      invalid(true)
    end

    it 'when invalid format then cannot parse' do
      invalid('01.0.0')
      invalid('1.01.0')
      invalid('1.1.01')
      invalid('2.x')
      invalid('2.3.x')
      invalid('2.3.1.4')
      invalid('2.3.1*beta')
      invalid('2.3.1-beta*')
      invalid('2.4.1-beta_4')
    end

    it 'semantic core version' do
      verify('1.0.0', 1, 0, 0, [], [])
      verify('14.165.14', 14, 165, 14, [], [])
    end

    it 'semantic version with prerelease' do
      verify('1.0.0-beta1', 1, 0, 0, ['beta1'], [])
      verify('1.0.0-beta.1', 1, 0, 0, ['beta', '1'], [])
      verify('1.0.0-x.y.z', 1, 0, 0, ['x', 'y', 'z'], [])
    end

    it 'semantic version with prerelease and build' do
      verify('1.0.0-beta.1+build.2', 1, 0, 0, ['beta', '1'], ['build', '2'])
    end

    it 'when minor or patch version is missing then fill with zero' do
      verify('15', 15, 0, 0, [], [])
      verify('15.143', 15, 143, 0, [], [])
      verify('15-x.y.z', 15, 0, 0, ['x', 'y', 'z'], [])
      verify('15-x.y.z+a.b.c', 15, 0, 0, ['x', 'y', 'z'], ['a', 'b', 'c'])
    end

    it 'compare' do

      # core
      expect(v('2.3.4') == v('2.3.4')).to eq(true)

      # core + prerelease
      expect(v('2.3.4-beta.1') == v('2.3.4-beta.1')).to eq(true)
      expect(v('2.3.4-beta.1') == v('2.3.4-beta.2')).to eq(false)

      # build
      expect(v('2.3.4+build.111') == v('2.3.4+build.222')).to eq(true)
      expect(v('2.3.4-beta+build.111') == v('2.3.4-beta+build.222')).to eq(true)

      # major
      expect(v('4.5.7') > v('3.5.7')).to eq(true)
      expect(v('2.5.7') < v('3.5.7')).to eq(true)

      # minor
      expect(v('3.6.7') > v('3.5.7')).to eq(true)
      expect(v('3.4.7') < v('3.5.7')).to eq(true)

      # patch
      expect(v('3.5.8') > v('3.5.7')).to eq(true)
      expect(v('3.5.6') < v('3.5.7')).to eq(true)

      # prerelease (numeric)
      expect(v('3.5.7-1') < v('3.5.7-2')).to eq(true)
      expect(v('3.5.7-1.1') < v('3.5.7-1.2')).to eq(true)
      expect(v('3.5.7-11') > v('3.5.7-1')).to eq(true)

      # prerelease (alphabetic)
      expect(v('3.5.7-a') == v('3.5.7-a')).to eq(true)
      expect(v('3.5.7-a') < v('3.5.7-b')).to eq(true)
      expect(v('3.5.7-az') > v('3.5.7-ab')).to eq(true)

      # prerelease (alphanumeric)
      expect(v('3.5.7-9') < v('3.5.7-a')).to eq(true)
      expect(v('3.5.7-a') < v('3.5.7-a-9')).to eq(true)
      expect(v('3.5.7-beta') > v('3.5.7-1')).to eq(true)
      expect(v('3.5.7-1beta') > v('3.5.7-1')).to eq(true)

      # prerelease (length)
      expect(v('3.5.7-alpha') < v('3.5.7-alpha.1')).to eq(true)
      expect(v('3.5.7-1.2.3') < v('3.5.7-a-1.2.3.4')).to eq(true)
    end
  end
end
