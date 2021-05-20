require 'octokit'
require_relative 'gapi_config'

############################################################################
# Copy issues and comments from one repository to another (sort of).       #
# Because there is no way to copy issues directly, this script will        #
# create new issues with the original metadata in the issue's body.        #
#                                                                          #
# NOTE: Assignees and issue status are included in the metadata block,     #
#       but the new issue itself will be open and unassigned.              #
#                                                                          #
# Inspired by https://github.com/IQAndreas/github-issues-import,           #
# the layout of issues and comments is very similar.                       #
#                                                                          #
# Requires GitHub's official OctoKit gem: http://octokit.github.io/        #
#                                                                          #
# Expects a configuration file named "gapi_config.rb" in this format:       #
#                                                                          #
# @gapi_config = {                                                         #
#     :api_key => "YOUR_API_KEY",                                          #
#     :origin_repo => "WHERE_THE_ISSUES_ARE_COMING_FROM",                  #
#     :dest_repo => "WHERE_THE_ISSUES_ARE_GOING",                          #
#     :source_labels => "LABELS_TO_FILTER_BY",                             #
#     :page_count => "HOW_MANY_PAGES_OF_ISSUES_TO_FETCH"                   #
# }                                                                        #
#                                                                          #
#                                                                          #
# LICENSE: Public Domain                                                   #
#                                                                          #
# USAGE:                                                                   #
#    Run as file from the command line                                     #
#    To copy a specific list of issues, change Line 162 to                 #
#        issue_list = get_issues([COMMA_SEPARATED_LIST_OF_INTEGERS])       #
#        (keep  the brackets, it expects an array)                         #
############################################################################

def create_client
    @client = Octokit::Client.new(:access_token => @gapi_config[:api_key])
    user = @client.user
    user.login
end

def get_issues(iss_numbers = nil)
    issue_list = []

    if iss_numbers.nil?
        1.upto(@gapi_config[:page_count]) do |pg|        
            issue_list << @client.list_issues(@gapi_config[:origin_repo], options = { :labels => @gapi_config[:source_labels], :state => "all", :page => pg })
        end
    else
        @gapi_config[:source_labels] = nil
        iss_numbers.each do |isn|
            begin
                issue_list << @client.issue(@gapi_config[:origin_repo], isn)
            rescue => e
                puts "***\nSkipping #{isn}:\n    #{e}\n***"
                next
            end
        end
    end

    return issue_list.flatten(1)
end

def get_new_issues
    issue_list = []
    
    1.upto(@gapi_config[:page_count]) do |pg| 
        issue_list << @client.list_issues(@gapi_config[:dest_repo], options = { :labels => @gapi_config[:source_labels], :state => "open", :page => pg })
    end
    return issue_list.flatten(1)
end

def get_comments(issue_id)    
    comment_list = @client.issue_comments(@gapi_config[:origin_repo], issue_id)
end

def issuemd(iss_data)    
    issue_markdown = []

    issue_markdown << "**Issue  by:** <a href='https://github.com/#{iss_data[:user][:login]}'>#{iss_data[:user][:login]}</a>" 
    issue_markdown << "**Original date:** #{iss_data[:created_at]}"
    issue_markdown << "**Originally opened as:** <a href='https://github.com/#{@gapi_config[:origin_repo]}/issues/#{iss_data[:number]}'>#{@gapi_config[:origin_repo]}/issues/#{iss_data[:number]}</a>"

    if !iss_data[:assignees].nil?
        assignees = []
        iss_data[:assignees].each { |ase| assignees << "<a href='https://github.com/#{ase[:login]}'>#{ase[:login]}</a>" unless ase[:login].nil? }
        issue_markdown << "**Original assignees:** #{assignees.join(', ')}"
    end

    issue_markdown << "**Status on #{Time.now.strftime('%Y-%m-%d')}:** #{iss_data[:state]}"

    issue_markdown << "<hr>\r\n"
    issue_markdown << iss_data[:body] unless iss_data[:body].nil?

    return issue_markdown.join("\n")
end

def commentmd(comm)    
    comment_markdown = []
    
    comment_markdown << "**Comment by:** <a href='https://github.com/#{comm[:user][:login]}'>#{comm[:user][:login]}</a>"
    comment_markdown << "**Original date:** #{comm[:created_at]}"
    comment_markdown << "<hr>\r\n"
    comment_markdown << comm[:body] unless comm[:body].nil?

    return comment_markdown.join("\n")
end

def milestone_id(ms_name = nil)    
    ms_list = (@client.list_milestones(@gapi_config[:dest_repo]))    
    ms_id = nil

    ms_list.each do |ms|
        ms_id = ms[:number] if  ms[:title] == ms_name
    end

    return ms_id
end

def copy_issue(this_iss)
    puts "  Copying issue #{this_iss[:number]}"
    iss_body = issuemd(this_iss)
    
    iss_labels = []    
    this_iss[:labels].each { |il| iss_labels << il[:name] }
   
    ms_title = this_iss[:milestone][:title] unless this_iss[:milestone].nil?
    ms_id = milestone_id(ms_title) unless ms_title.nil?
    
    if ms_id.nil? && !this_iss[:milestone].nil?
        @client.create_milestone(@gapi_config[:dest_repo], ms_title)
        ms_id = milestone_id(ms_title)
    end

    @client.create_issue(@gapi_config[:dest_repo], this_iss[:title], iss_body, options = { :labels => iss_labels.join(','), :milestone => ms_id })

    puts "\t--copy complete."
end

def copy_issue_comments(old_id, new_id)
    puts "Copying comments from #{old_id} to #{new_id}"
    comm_list = @client.issue_comments(@gapi_config[:origin_repo], old_id)

    comm_list.each do |comm|
        @client.add_comment(@gapi_config[:dest_repo], new_id, commentmd(comm))
    end
    puts "\t--copy complete."
end


if __FILE__ == $0
    # Set up error counts
    iss_errors = 0
    num_errors = 0
    comm_errors = 0

    # Login with API Token
    create_client

    # Gets list of issues based on options in gapi_config
    # To get specific issues, instead, use get_issues([1,2,3])
    puts "\r\nGetting original issues"
    issue_list = get_issues

    puts "\r\nCopying issues to new repo"    
    # Copies to target repository specified in @gapi_config[:dest_repo]
    issue_list.reverse.each  do |iss|
        begin
            copy_issue(iss) 
        rescue => e
            iss_errors += 1
            puts "  ***\nFailed to copy issue #{iss[:number]}:\n   #{e}\n***"
        next    
        end
    end

    # Get data for the new issues
    puts "\r\nGetting new issue data"
    new_list = get_new_issues

    issue_numbers = []

    puts "\r\nGetting issues with comments"
    
    # Using  title, match old issue numbers to new issue numbers
    issue_list.each do |oiss|     
        if oiss[:comments] > 0   
            puts "  Matching titles for #{oiss[:number]}: #{oiss[:title]}"
            begin
                new_iss = new_list.select { |iss| iss[:title] == oiss[:title] unless iss[:title].nil? }
            rescue => e
                num_errors += 1
                puts "  ***\nFailed to match #{oiss[:number]} with an issue in the destination repository:   \n#{e}\n***"
            end
           
            puts "  Adding issue number pair to array:"
            issue_numbers << [oiss[:number], new_iss[0][:number]] if !new_iss.nil?
           
            puts "  Added  [#{oiss[:number]}, #{new_iss[0][:number]}]"
        end
    end

    puts "  ...no issues with comments found." if issue_numbers.empty?
    
    # Adds comments to the issues in the target repository
    puts "\r\nCopying comments to new issues" unless issue_numbers.empty?
    issue_numbers.each  do |iss| 
        begin
            copy_issue_comments(iss[0], iss[1])
        rescue => e
            comm_errors += 1
            puts "  ***\nFailed to copy comments from issue  number #{old_id} to issue #{new_id}:\n   #{e}\n***"
            next
        end
    end

    puts "\r\n---------------"
    puts "Issue errors: #{iss_errors} for #{issue_list.count} total issues"
    puts "Pair matching errors: #{num_errors}"
    puts "Comment errors: #{comm_errors}"
end