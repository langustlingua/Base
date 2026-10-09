'use strict';

const discoveryView = { tab:'scripts', category:'all', status:'all', query:'' };
const discoveryId = id => 'discover#' + id;
const discoveryEscape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function discoveryReel(id) { return DISCOVERY.reels.find(r => r.id === id); }
function discoveryScript(r) { const key='discover_script_'+r.id; return STATE.edits[key] === undefined ? r.script : STATE.edits[key]; }
function discoveryCategory(r) { return DISCOVERY.categories.find(c => c.id === r.category); }
function discoveryDuration(r) {
  const words = discoveryScript(r).trim().split(/\s+/).filter(Boolean).length;
  return Math.max(5,Math.round(words/2.3))+'–'+Math.max(7,Math.round(words/1.8))+' сек · ориентир';
}
function discoveryItems() {
  return DISCOVERY.reels.map(r => ({id:discoveryId(r.id),section:'x_discover',type:'discovery',label:'✦ Познавательный рилс',idx:r.id,title:r.title,
    text:discoveryScript(r)+'\n\nФакт: '+r.fact+'\n\nИсточники:\n'+r.sources.map(key => DISCOVERY.sources[key].label+'\n'+DISCOVERY.sources[key].url).join('\n\n'),extra:discoveryCategory(r).label}));
}

function renderDiscovery() {
  const done=DISCOVERY.reels.filter(r => isDone(discoveryId(r.id))).length;
  document.getElementById('sec-x_discover').innerHTML=`
    <div class="discover-hero">
      <div class="discover-kicker">LANGUST · Контент через любопытство</div>
      <h1>Познавательные рилсы</h1>
      <p>Маленькое открытие, которое хочется рассказать ребёнку. Готовые истории для мам младших школьников — в голосе «Афина дома».</p>
      <div class="discover-stats"><span><b>${DISCOVERY.reels.length}</b> сценариев</span><span><b>6</b> направлений</span><span><b id="discover-done-total">${done}</b> снято</span></div>
    </div>
    <div class="discover-tabs" role="tablist" aria-label="Познавательный контент">
      ${[['scripts','Сценарии'],['plan','План на месяц'],['research','Исследование']].map(([id,label])=>`<button type="button" role="tab" id="discover-tab-${id}" aria-controls="discover-panel" aria-selected="${discoveryView.tab===id}" tabindex="${discoveryView.tab===id?'0':'-1'}" data-tab="${id}">${label}</button>`).join('')}
    </div>
    <div id="discover-panel" role="tabpanel" aria-labelledby="discover-tab-${discoveryView.tab}"></div>
    <p class="discover-footnote">Избранное, отметки «снято» и ваши версии сценариев сохраняются в этом браузере. Исходные факты и ссылки остаются в карточках. Подготовлено ${DISCOVERY.reviewed}.</p>`;
  document.querySelectorAll('.discover-tabs [data-tab]').forEach(button => {
    button.addEventListener('click',()=>discoverySetTab(button.dataset.tab));
    button.addEventListener('keydown',event => {
      const tabs=['scripts','plan','research']; let next=tabs.indexOf(button.dataset.tab);
      if(event.key==='ArrowRight') next=(next+1)%tabs.length;
      else if(event.key==='ArrowLeft') next=(next+tabs.length-1)%tabs.length;
      else if(event.key==='Home') next=0;
      else if(event.key==='End') next=tabs.length-1;
      else return;
      event.preventDefault();discoverySetTab(tabs[next]);
    });
  });
  if(discoveryView.tab==='scripts') discoveryRenderScripts();
  else if(discoveryView.tab==='plan') discoveryRenderPlan();
  else discoveryRenderResearch();
}
function discoverySetTab(tab) { discoveryView.tab=tab;renderDiscovery();document.getElementById('discover-tab-'+tab).focus({preventScroll:true}); }
function discoveryRenderScripts() {
  document.getElementById('discover-panel').innerHTML=`
    <p class="discover-intro">Один ролик — один факт, понятное объяснение и повод поговорить с ребёнком. Откройте карточку: внутри полный текст, план съёмки и источник.</p>
    <div class="discover-controls">
      <div class="discover-search-row"><div><label for="discover-search">Найти тему или слово</label><input type="search" id="discover-search" placeholder="LEGO, память, Minecraft…" value="${discoveryEscape(discoveryView.query)}"></div><div><label for="discover-status">Показать</label><select id="discover-status"><option value="all">Все сценарии</option><option value="todo">Ещё не снято</option><option value="fav">Избранное</option><option value="done">Уже снято</option></select></div></div>
      <div class="discover-filters" role="group" aria-label="Направление">${[{id:'all',label:'Все темы'},...DISCOVERY.categories].map(c=>`<button type="button" data-category="${c.id}" aria-pressed="${discoveryView.category===c.id}">${discoveryEscape(c.label)}</button>`).join('')}</div>
    </div><p class="discover-result-count" id="discover-results" role="status" aria-live="polite"></p><div id="discover-list"></div>`;
  const select=document.getElementById('discover-status');select.value=discoveryView.status;
  select.addEventListener('change',()=>{discoveryView.status=select.value;discoveryDrawCards();});
  document.getElementById('discover-search').addEventListener('input',event=>{discoveryView.query=event.target.value;discoveryDrawCards();});
  document.querySelectorAll('[data-category]').forEach(button=>button.addEventListener('click',()=>{
    discoveryView.category=button.dataset.category;
    document.querySelectorAll('[data-category]').forEach(b=>b.setAttribute('aria-pressed',b===button?'true':'false'));
    discoveryDrawCards();
  }));
  discoveryDrawCards();
}
function discoveryFiltered() {
  const query=discoveryView.query.trim().toLocaleLowerCase('ru');
  return DISCOVERY.reels.filter(r=>{
    const id=discoveryId(r.id);
    return (discoveryView.category==='all'||r.category===discoveryView.category)
      && (discoveryView.status==='all'||(discoveryView.status==='fav'&&isFav(id))||(discoveryView.status==='done'&&isDone(id))||(discoveryView.status==='todo'&&!isDone(id)))
      && (!query||[r.title,r.fact,discoveryScript(r),discoveryCategory(r).label].join(' ').toLocaleLowerCase('ru').includes(query));
  });
}
function discoveryDrawCards() {
  const list=document.getElementById('discover-list');
  const openIds=new Set(Array.from(list.querySelectorAll('details.discover-card[open]'),el=>el.dataset.reel));
  const reels=discoveryFiltered();
  document.getElementById('discover-results').textContent=`Показано ${reels.length} из ${DISCOVERY.reels.length} сценариев`;
  list.innerHTML=reels.length?reels.map(r=>discoveryCard(r,openIds.has(r.id))).join(''):
    '<div class="discover-empty"><p>В этой подборке пока нет сценариев.</p><button type="button" id="discover-reset-filters">Сбросить фильтры</button></div>';
  list.querySelectorAll('[data-action]').forEach(button=>button.addEventListener('click',()=>discoveryAction(button)));
  list.querySelectorAll('textarea[data-script]').forEach(area=>area.addEventListener('input',()=>{
    STATE.edits['discover_script_'+area.dataset.script]=area.value;saveState();
    document.getElementById('discover-script-'+area.dataset.script).textContent=area.value;
    document.getElementById('discover-duration-'+area.dataset.script).textContent=discoveryDuration(discoveryReel(area.dataset.script));
  }));
  const reset=document.getElementById('discover-reset-filters');if(reset)reset.addEventListener('click',()=>{discoveryResetFilters();discoveryRenderScripts();});
}
function discoveryCard(r,open) {
  const escape=discoveryEscape,id=discoveryId(r.id),category=discoveryCategory(r);
  return `<details class="discover-card" id="discover-card-${r.id}" data-reel="${r.id}" ${open?'open':''}>
    <summary><div class="discover-card-meta">${escape(r.series)}<span class="discover-topic">· ${escape(category.label)}</span></div><h2>${escape(r.title)}</h2><p class="discover-card-description">${escape(r.why)}</p><span class="discover-status">${isDone(id)?'✓ Снято · ':''}${isFav(id)?'★ В избранном · ':''}Цель: ${escape(r.goal.toLowerCase())}</span></summary>
    <div class="discover-card-body">
      <div class="discover-fact"><strong>Факт и его границы</strong>${escape(r.fact)}</div>
      <div class="discover-label"><span>Готовый текст для озвучки</span><span id="discover-duration-${r.id}">${escape(discoveryDuration(r))}</span></div>
      <div class="discover-script" id="discover-script-${r.id}">${escape(discoveryScript(r))}</div>
      <details class="discover-editor"><summary>Моя версия сценария</summary><label class="discover-help" for="discover-edit-${r.id}">Изменения сохраняются автоматически в этом браузере.</label><textarea id="discover-edit-${r.id}" data-script="${r.id}">${escape(discoveryScript(r))}</textarea><button type="button" class="discover-textbutton" data-action="restore" data-id="${r.id}">Вернуть исходный текст</button></details>
      <div class="discover-actions"><button type="button" data-action="copy" data-id="${r.id}">Копировать текст</button><button type="button" data-action="fav" data-id="${r.id}" aria-pressed="${isFav(id)}">${isFav(id)?'★ В избранном':'☆ В избранное'}</button><button type="button" data-action="done" data-id="${r.id}" aria-pressed="${isDone(id)}">${isDone(id)?'✓ Снято':'Отметить снятым'}</button></div>
      <div class="discover-detail"><h3>Что показать в кадре</h3><ol>${r.shots.map(shot=>`<li>${escape(shot)}</li>`).join('')}</ol></div>
      <div class="discover-detail"><h3>Связь с LANGUST</h3><p>${escape(r.bridge)}</p></div>
      <div class="discover-caution"><strong>Точность формулировки.</strong> ${escape(r.caution)}</div>
      <div class="discover-sources">${r.sources.map(key=>{const s=DISCOVERY.sources[key];return `<a href="${escape(s.url)}" target="_blank" rel="noopener noreferrer">${escape(s.label)} ↗</a>`;}).join('<br>')}<p>Источник проверен ${DISCOVERY.reviewed}. Сценарий — авторская адаптация факта для короткого ролика.</p></div>
    </div></details>`;
}
function discoveryAction(button) {
  const id=button.dataset.id,r=discoveryReel(id);if(!r)return;
  if(button.dataset.action==='copy'){discoveryCopy(discoveryScript(r),'Текст для озвучки скопирован');return;}
  if(button.dataset.action==='restore') {
    if(!window.confirm('Вернуть исходный сценарий? Ваша версия этой карточки будет заменена.'))return;
    delete STATE.edits['discover_script_'+id];saveState();
  }
  if(button.dataset.action==='fav')toggleFav(discoveryId(id));
  if(button.dataset.action==='done')toggleDone(discoveryId(id));
  discoveryDrawCards();
  document.getElementById('discover-done-total').textContent=DISCOVERY.reels.filter(item=>isDone(discoveryId(item.id))).length;
  const replacement=document.querySelector(`#discover-card-${id} [data-action="${button.dataset.action}"]`);
  if(replacement)replacement.focus({preventScroll:true});
  else document.getElementById('discover-status').focus({preventScroll:true});
}
async function discoveryCopy(text,message) {
  try { await navigator.clipboard.writeText(text);toast(message||'Скопировано'); }
  catch(error) {
    openM('Скопируйте текст вручную','<p class="discover-help">Буфер обмена недоступен. Выделите и скопируйте текст.</p><textarea id="discover-copy-fallback" rows="12" readonly>'+discoveryEscape(text)+'</textarea>',()=>{});
    const area=document.getElementById('discover-copy-fallback');area.focus();area.select();
  }
}
function discoveryResetFilters(){discoveryView.category='all';discoveryView.status='all';discoveryView.query='';}
function discoveryOpen(id) {
  discoveryView.tab='scripts';discoveryResetFilters();renderDiscovery();
  const card=document.getElementById('discover-card-'+id);
  if(card){card.open=true;card.querySelector('summary').focus({preventScroll:true});card.scrollIntoView({block:'start'});}
}
function discoveryRenderPlan() {
  document.getElementById('discover-panel').innerHTML=`<p class="discover-intro">12 роликов, по три в неделю. Это первый редакционный тест: длительность и подачу выбираем сопоставимыми, результаты оцениваем серией.</p>
    ${DISCOVERY.weeks.map((week,index)=>`<section class="discover-week"><h2>${discoveryEscape(week.title)}</h2>${week.ids.map((id,i)=>{const r=discoveryReel(id);return `<button class="discover-plan-item" type="button" data-open="${id}"><span>${isDone(discoveryId(id))?'✓':String(index*3+i+1).padStart(2,'0')}</span><span>${discoveryEscape(r.title)}<small>${discoveryEscape(discoveryCategory(r).label)} · ${discoveryEscape(r.goal)}</small></span></button>`;}).join('')}<p><strong>На что смотрим:</strong> ${discoveryEscape(week.question)}</p></section>`).join('')}
    <div class="discover-actions"><button type="button" id="discover-copy-plan">Копировать план на месяц</button></div>
    <div class="card discover-report"><h3>Как оценивать результат</h3><p>Через одинаковый срок после публикации запишите охват, подписки от ролика (если площадка их показывает), пересылки и сохранения. Сравнивайте подписки и пересылки на 1 000 охваченных аккаунтов, а не только абсолютные просмотры.</p><p>Отдельно отмечайте вопросы родителей о классе, школьном английском и Spotlight. Это качественный сигнал, а не точное определение состава аудитории. По одному ролику вывод не делаем: удачный сюжет проверяем ещё несколькими выпусками.</p><p>Два выпуска на тему дают предварительный сигнал, а не доказательство. Нормативы и обещания роста заранее не задаём.</p></div>`;
  document.querySelectorAll('[data-open]').forEach(button=>button.addEventListener('click',()=>discoveryOpen(button.dataset.open)));
  document.getElementById('discover-copy-plan').addEventListener('click',()=>discoveryCopy(DISCOVERY.weeks.map(week=>week.title+'\n'+week.ids.map(id=>'• '+discoveryReel(id).title).join('\n')+'\nНаблюдение: '+week.question).join('\n\n'),'План на месяц скопирован'));
}
function discoveryRenderResearch() {
  document.getElementById('discover-panel').innerHTML=`<div class="discover-report">
    <p class="discover-intro">Задача: привлечь мам младших школьников через интерес к миру и укрепить доверие к тому, как Татьяна объясняет. Ядро LANGUST — школьный английский по Spotlight.</p>
    <h2>Шесть смежных направлений</h2>
    <div class="discover-category-grid">${DISCOVERY.categories.map(c=>`<div class="discover-category-box"><small>${discoveryEscape(c.priority)}</small><h3>${discoveryEscape(c.label)}</h3><p>${discoveryEscape(c.purpose)}</p></div>`).join('')}</div>
    <h2>Что показали открытые данные</h2>
    <div class="card"><h3>Родителям трудно с домашними заданиями</h3><p>В опросе Anketolog (1900 родителей и детей школьного возраста, февраль 2025) среди трудностей отмечались объём заданий — 53%, нехватка мотивации — 49%, сложный материал — 42%.</p><a href="https://iom.anketolog.ru/2025/04/04/domashnie-zadaniya" target="_blank" rel="noopener noreferrer">Опрос и методология ↗</a></div>
    <div class="card"><h3>Нужны понятный прогресс и интерес к учёбе</h3><p>В онлайн-опросе Учи.ру и «Ренессанс страхования» (814 родителей из городов-миллионников, август 2026) 36,7% затруднялись оценить знания ребёнка, а 31% переживали, что занятия будут ему неинтересны.</p><a href="https://www.renins.ru/press/news/item/kazhdomu-tretemu-roditelyu-trudno-otsenit-gotovnost-rebenka-k-shkole/" target="_blank" rel="noopener noreferrer">Исследование и выборка ↗</a></div>
    <p>Оба опроса охватывают родителей школьников разных возрастов. Их нельзя выдавать за точную статистику мам второклассников. Данных о конверсии чужих Reels в подписки нет; приоритеты рубрик — наши гипотезы для теста.</p>
    <h2>Что уже есть в контентном поле</h2>
    <div class="card"><p><a href="https://skysmart.ru/articles/useful/deti-i-domashka" target="_blank" rel="noopener noreferrer">Skysmart</a>: бытовые ситуации с домашкой, юмор и родительские советы.</p><p><a href="https://www.novakid.ru/blog/5kak-pomoch-rebenku-polyubit-angliyskiy/" target="_blank" rel="noopener noreferrer">Novakid</a>: игры и домашняя языковая практика.</p><p><a href="https://externat.foxford.ru/" target="_blank" rel="noopener noreferrer">Фоксфорд</a>: родительство, любознательность и занятия после школы.</p><p><a href="https://t.me/s/matematik_andrei_channel?before=4334" target="_blank" rel="noopener noreferrer">Математик Андрей</a>: задачки из жизни, юмор и личность преподавателя.</p><p>Это наблюдения по открытым материалам, не рейтинг эффективности и не полный аудит аккаунтов.</p></div>
    <h2>Как это работает для LANGUST</h2><ol><li><strong>Внимание:</strong> знакомый предмет или герой и неожиданный вопрос.</li><li><strong>Доверие:</strong> точное объяснение, понятный пример, доступный источник.</li><li><strong>Подписка:</strong> узнаваемая серия и обещание следующего интересного открытия.</li></ol>
    <p style="margin-top:12px">Голос — «Афина дома»: спокойно, тепло, по существу. Домашний свет, предмет в руках, один законченный сюжет. Английский связываем с темой там, где связь естественна.</p>
    <h2>Редакционные ориентиры</h2><ul><li>Факт, вывод из исследования и предложение попробовать дома называем отдельно.</li><li>Для исследований указываем возраст и задачу; не придумываем универсальные интервалы и проценты.</li><li>Без обещаний пятёрок, гарантированной самостоятельности и выдуманных кейсов.</li><li>Собственные демонстрации вместо чужих видео. Если используем фото или иллюстрацию, проверяем право на использование.</li><li>Истории о природе и других странах дополняют языковые рубрики; их охват сам по себе ещё не означает интерес к курсу.</li></ul>
    <p class="discover-footnote">Основание: открытые источники и исследование от ${DISCOVERY.reviewed}. После пилота пересмотреть распределение тем по фактическому отклику вашей аудитории.</p>
  </div>`;
}
