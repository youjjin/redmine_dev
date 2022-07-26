# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012 Daniel Munn <dan.munn@munnster.co.uk>
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

require 'fileutils'
require 'uuidtools'

class Dmsf144 < ActiveRecord::Migration[4.2]

  class DmsfFileLock < ActiveRecord::Base
    belongs_to :file, class_name: 'DmsfFile', foreign_key: 'dmsf_file_id'
    belongs_to :user
  end  

  def up
    # Add our entity_type column (used with our entity type)
    add_column :dmsf_file_locks, :entity_type, :integer, null: true
    # Add our lock relevent columns (ENUM) - null (till we upgrade data)
    add_column :dmsf_file_locks, :lock_type_cd, :integer, null: true
    add_column :dmsf_file_locks, :lock_scope_cd, :integer, null: true
    add_column :dmsf_file_locks, :uuid, :string, null: true, limit: 36
    # Add our expires_at column
    add_column :dmsf_file_locks, :expires_at, :datetime, null: true
    do_not_delete = []
    # - 2012-07-12: Better compatibility for postgres - query used 3 columns however
    #               only on appearing in group, find_each imposes a limit and incorrect
    #               ordering, so adapted that, we grab id's load a mock object, and reload
    #               data into it, which should enable us to run checks we need, not as
    #               efficient, however compatible across the board.
    DmsfFileLock.reset_column_information
    DmsfFileLock.select('MAX(id), id').order(Arel.sql('MAX(id) DESC')).group(:dmsf_file_id, :id).find do |lock|
      lock.reload 
      if lock.locked
        do_not_delete << lock.id
      end
    end
    # Generate new lock Id's for whats being persisted
    do_not_delete.each do |l|
      # Find the lock
      next unless lock = DmsfFileLock.find(l)
      lock.uuid = UUIDTools::UUID.random_create.to_s
      lock.save!
    end
    say "Preserving #{do_not_delete.count} file lock(s) found in old schema"
    DmsfFileLock.where.not(id: do_not_delete).delete_all
    # We need to force our newly found
    say 'Applying default lock scope / type - Exclusive / Write'
    DmsfFileLock.update_all(entity_type: 0, lock_type_cd: 0, lock_scope_cd: 0)
    # These are not null-allowed columns
    change_column :dmsf_file_locks, :entity_type, :integer, null: false
    change_column :dmsf_file_locks, :lock_type_cd, :integer, null: false
    change_column :dmsf_file_locks, :lock_scope_cd, :integer, null: false
    # Data cleanup
    rename_column :dmsf_file_locks, :dmsf_file_id, :entity_id
    remove_column :dmsf_file_locks, :locked
    rename_table :dmsf_file_locks, :dmsf_locks
    # Not sure if this is the right place to do this, as its file manipulation, not database (strictly)
    say 'Completing one-time file migration ...'
    begin
      DmsfFileRevision.find_each do |rev|
        next unless rev.project
        existing = DmsfFile.storage_path.join rev.disk_filename
        new_path = rev.disk_file(false)
        begin
          if File.exist?(existing)
            if File.exist?(new_path)
              rev.disk_filename = rev.new_storage_filename
              new_path = rev.disk_file(false)
              rev.save!
            end
            # Ensure the project path exists
            project_directory = File.dirname(new_path)
            Dir.mkdir(project_directory) unless File.directory? project_directory
            FileUtils.mv existing, new_path
            say "Migration: #{existing} -> #{new_path} succeeded"
          end
        rescue #Here we wrap around IO in the loop to prevent one failure ruining complete run.
          say "Migration: #{existing} -> #{new_path} failed"
        end
      end
      say 'Action was successful'
    rescue => e
      say 'Action was not successful'
      puts e.message
      puts e.backtrace.inspect # See issue #86
      # Nothing here, we just dont want a migration to break
    end
  end

  def self.down
    rename_table :dmsf_locks, :dmsf_file_locks
    add_column :dmsf_file_locks, :locked, :boolean, default: false, null: false
    # Data cleanup - delete all expired locks, or any folder locks
    DmsfFileLock.reset_column_information
    say 'Removing all expired and/or folder locks'
    DmsfFileLock.where(['expires_at < ? OR entity_type = 1', Time.current]).delete_all
    say 'Changing all records to be locked'
    DmsfFileLock.update_all(locked: true)
    rename_column :dmsf_file_locks, :entity_id, :dmsf_file_id
    remove_column :dmsf_file_locks, :entity_type
    remove_column :dmsf_file_locks, :lock_type_cd
    remove_column :dmsf_file_locks, :lock_scope_cd
    remove_column :dmsf_file_locks, :expires_at
    remove_column :dmsf_file_locks, :uuid
    # Not sure if this is the right place to do this, as its file manipulation, not database (stricly)
    begin
      say 'restoring old file-structure'
      DmsfFileRevision.find_each do |rev|
        next unless rev.project
        project = rev.project.identifier.gsub(/[^\w\.\-]/, '_')
        existing = DmsfFile.storage_path.join("p_#{project}/#{rev.disk_filename}")
        new_path = DmsfFile.storage_path.join(rev.disk_filename)
        if File.exist?(existing)
          if File.exist?(new_path)
            rev.disk_filename = rev.new_storage_filename
            rev.save!
            new_path = DmsfFile.storage_path.join(rev.disk_filename)
          end
          FileUtils.mv existing, new_path
        end
      end
    rescue
      # Nothing here, we just dont want a migration to break
    end
  end

end
