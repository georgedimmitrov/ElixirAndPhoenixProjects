import {Socket} from "phoenix";

let socket = new Socket("/socket", {params: {token: window.userToken}});

socket.connect();

const createSocket = (topicId) => {
  // Now that you are connected, you can join channels with a topic:
  let channel = socket.channel(`comments:${topicId}`, {})
  channel.join()
    .receive("ok", resp => {
      console.log(resp);
      renderComments(resp.comments);
    })
    .receive("error", resp => {
      console.log("Unable to join", resp);
    });
  
  channel.on(`comments:${topicId}:new`, renderComment);

  document.querySelector('button').addEventListener('click', () => {
    const textarea = document.querySelector('textarea');

    channel.push('comment:add', { content: textarea.value });

    textarea.value = '';
  });
};

// initial render pass that renders all existing comments
function renderComments(comments) {
  const renderedComments = comments.map(comment => {
    return commentTemplate(comment);
  }).join('');

  document.querySelector('.collection').innerHTML = renderedComments;
}

// single comment was added and we display it with sockets immediatelly
function renderComment(event) {
  const renderedComment = commentTemplate(event.comment);

  document.querySelector('.collection').innerHTML += renderedComment;
}

// simple helper function to avoid repetition of HTML creation
function commentTemplate(comment) {
  let email = 'Anonymous';

  if (comment.user) {
    email = comment.user.email;
  }
  
  return `
    <li class="collection-item">
      ${comment.content}
      <div class="secondary-content">
        ${email}
      </div>
    </li>
  `;
}

window.createSocket = createSocket;
