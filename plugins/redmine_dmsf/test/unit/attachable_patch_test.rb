# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-22 Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class AttachablePatchTest < RedmineDmsf::Test::UnitTest

  fixtures :issues, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @issue1 = Issue.find 1
    @issue2 = Issue.find 2
  end

  def test_has_attachmets
    if defined?(EasyExtensions)
      assert @issue1.has_attachments?
      assert !@issue2.has_attachments?
    else
      assert @issue1.dmsf_files.any?
      assert !@issue2.dmsf_files.any?
    end
  end

end