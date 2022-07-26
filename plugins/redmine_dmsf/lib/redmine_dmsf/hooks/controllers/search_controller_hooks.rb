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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module RedmineDmsf
  module Hooks
    module Controllers
    
      class SearchControllerHooks < Redmine::Hook::Listener
        include Rails.application.routes.url_helpers

        def controller_search_quick_jump(context={})
          if context.is_a?(Hash)
            question = context[:question]
            if question.present?
              if question.match(/^D(\d+)$/) && DmsfFile.visible.where(id: $1).exists?
                return dmsf_file_path(id: $1)
              end
            end
          end
        end

      end

    end
  end
end